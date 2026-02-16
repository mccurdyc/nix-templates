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
  options.perSystem = mkPerSystemOption ({ pkgs, ... }: {
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
        default = pkgs.nixpkgs-fmt;
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

      dockerfileInputs =
        if (options.mccurdyc ? dockerfile && config.mccurdyc.dockerfile.enable) then
          [ config.devShells.dockerfile ]
        else
          [ ];
    in
    lib.mkIf cfg.enable {
      inherit (cfg) formatter;

      # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
      devShells.default = pkgs.mkShell {
        inputsFrom = preCommitInputs ++ dockerfileInputs ++ cfg.extraInputsFrom;

        packages = buildPackages
          ++ nixPackages
          ++ containerPackages
          ++ cfg.extraPackages;
      };
    };
}
