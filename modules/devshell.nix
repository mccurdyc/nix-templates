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
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.mccurdyc.devshell = {
      enable = lib.mkEnableOption "development shell" // {
        default = true;
      };

      build = {
        enable = lib.mkEnableOption "build tools (just)" // {
          default = true;
        };
      };

      nix = {
        enable = lib.mkEnableOption "Nix tools (statix, nixfmt, nil)" // {
          default = true;
        };
      };

      container = {
        enable = lib.mkEnableOption "container tools (hadolint, dockerfile-language-server, dive)" // {
          default = false;
        };
      };

      formatter = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
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

      extraShellHook = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra shell hook commands to run when entering the shell.";
      };
    };
  });

  config.perSystem =
    {
      config,
      pkgs,
      options,
      ...
    }:
    let
      cfg = config.mccurdyc.devshell;

      buildPackages = lib.optionals cfg.build.enable [
        pkgs.just
        pkgs.shfmt
      ];

      nixPackages = lib.optionals cfg.nix.enable [
        pkgs.deadnix
        pkgs.nil
        pkgs.nixfmt
        pkgs.statix
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

      docsCfg = config.mccurdyc.docs or { };

      docsShellHook =
        let
          mkDocHook =
            name: fileCfg:
            if (options.mccurdyc ? docs && (fileCfg.enable or false)) then
              ''
                if [ ! -f docs/${name} ]; then
                  mkdir -p docs
                  cat > docs/${name} << '__MCCURDYC_DOCS_EOF__'
                ${fileCfg.content}
                __MCCURDYC_DOCS_EOF__
                  echo "Created docs/${name}"
                fi
              ''
            else
              "";
        in
        (mkDocHook "RUNBOOK.md" (docsCfg.runbook or { }))
        + (mkDocHook "cue.md" (docsCfg.cue or { }))
        + (mkDocHook "nix.md" (docsCfg.nix or { }));
    in
    lib.mkIf cfg.enable {
      mccurdyc.devshell.formatter = lib.mkDefault (
        if (options ? treefmt && config.mccurdyc.pre-commit.enable) then
          config.treefmt.build.wrapper
        else
          pkgs.nixfmt
      );

      formatter = lib.mkIf (cfg.formatter != null) cfg.formatter;

      # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
      devShells.default = pkgs.mkShell {
        inputsFrom = preCommitInputs ++ cfg.extraInputsFrom;

        shellHook = dockerfileShellHook + docsShellHook + cfg.extraShellHook;

        packages = buildPackages ++ nixPackages ++ containerPackages ++ cfg.extraPackages;
      };
    };
}
