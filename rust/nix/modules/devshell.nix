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
#     rust.enable = true;
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
        enable = lib.mkEnableOption "container tools (hadolint, dockerfile-language-server, dive)" // { default = true; };
      };

      rust = {
        enable = lib.mkEnableOption "Rust development shell from rust-flake" // { default = false; };
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

  config.perSystem = { self', config, pkgs, ... }:
    let
      cfg = config.mccurdyc.devshell;

      buildPackages = lib.optionals cfg.build.enable [
        pkgs.just
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

      rustInputs = lib.optionals cfg.rust.enable [
        self'.devShells.rust
      ];

      preCommitInputs = lib.optionals config.mccurdyc.pre-commit.enable [
        config.pre-commit.devShell
      ];
    in
    lib.mkIf cfg.enable {
      inherit (cfg) formatter;

      # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
      devShells.default = pkgs.mkShell {
        # TODO: the rust inputs should be passed in from the consuming rust flake.
        inputsFrom = rustInputs ++ preCommitInputs ++ cfg.extraInputsFrom;

        packages = buildPackages
          ++ nixPackages
          ++ containerPackages
          ++ cfg.extraPackages;
      };
    };
}
