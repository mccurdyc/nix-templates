# Development shell configuration module
#
# This is a flake-parts perSystem module that provides a configurable
# development shell with common tools for various project types.
#
# Usage in your flake:
#   imports = [ ./nix/modules/devshell.nix ];
#
# Configuration example:
#   perSystem.mccurdyc.devshell = {
#     enable = true;
#     build.enable = true;
#     nix.enable = true;
#     container.enable = false;
#     extraPackages = [ pkgs.myTool ];
#   };
{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption (_: {
    options.mccurdyc.devshell = {
      enable = lib.mkEnableOption "development shell" // { default = true; };

      build = {
        enable = lib.mkEnableOption "build tools (just)" // { default = true; };
      };

      nix = {
        enable = lib.mkEnableOption "Nix tools (statix, nixpkgs-fmt, nil)" // { default = true; };
      };

      container = {
        enable = lib.mkEnableOption "container tools (hadolint, dockerfile-language-server, dive)" // { default = false; };
      };

      formatter = lib.mkOption {
        type = lib.types.package;
        description = "Formatter package for 'nix fmt'";
      };

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Additional packages to include in the dev shell";
      };

      extraInputsFrom = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Additional shells to inherit from via inputsFrom";
      };
    };
  });

  config.perSystem = { config, pkgs, options, ... }:
    let
      cfg = config.mccurdyc.devshell;

      buildPackages = lib.optionals cfg.build.enable [
        pkgs.just
        pkgs.shfmt
      ];

      nixPackages = lib.optionals cfg.nix.enable [
        pkgs.statix
        pkgs.nixpkgs-fmt
        pkgs.nil
      ];

      containerPackages = lib.optionals cfg.container.enable [
        pkgs.hadolint
        pkgs.dockerfile-language-server
        pkgs.dive
      ];

      preCommitInputs =
        if (options.mccurdyc ? pre-commit && config.mccurdyc.pre-commit.enable) then
          [ config.pre-commit.devShell ]
        else
          [ ];

      dockerfileCfg = config.mccurdyc.dockerfile or { };

      dockerfileShellHook =
        if (options.mccurdyc ? dockerfile && dockerfileCfg.enable or false) then
          ''
            # Generate .dockerignore if missing
            if [ ! -f .dockerignore ]; then
              cat > .dockerignore << 'EOF'
            ${dockerfileCfg.baseIgnore}
            ${dockerfileCfg.extraIgnore}
            EOF
              echo "Created .dockerignore"
            fi

            # Generate Dockerfile if missing
            if [ ! -f Dockerfile ]; then
              cat > Dockerfile << 'EOF'
            ${dockerfileCfg.content}
            EOF
              echo "Created Dockerfile"
            fi
          ''
        else
          "";
    in
    lib.mkIf cfg.enable {
      mccurdyc.devshell.formatter = lib.mkDefault pkgs.nixpkgs-fmt;

      inherit (cfg) formatter;

      # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
      devShells.default = pkgs.mkShell {
        inputsFrom = preCommitInputs ++ cfg.extraInputsFrom;

        shellHook = dockerfileShellHook;

        packages = buildPackages
          ++ nixPackages
          ++ containerPackages
          ++ cfg.extraPackages;
      };
    };
}
