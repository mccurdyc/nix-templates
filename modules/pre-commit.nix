# Pre-commit hooks configuration module
#
# This is a flake-parts perSystem module that provides configurable git-hooks.nix
# (pre-commit hooks) for various project types.
#
# Usage in your flake:
#   imports = [ ./nix/modules/pre-commit.nix ];
#
# Configuration example:
#   perSystem.mccurdyc.pre-commit = {
#     enable = true;
#     nix.enable = true;
#     rust.enable = true;
#     shell.enable = false;
#     just.enable = true;
#   };
{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption (_: {
    options.mccurdyc.pre-commit = {
      enable = lib.mkEnableOption "pre-commit hooks" // { default = true; };

      nix = {
        enable = lib.mkEnableOption "Nix hooks (flake-checker, deadnix, nixpkgs-fmt, statix, nil)" // { default = true; };
      };

      rust = {
        enable = lib.mkEnableOption "Rust hooks (rustfmt, cargo-check, clippy)" // { default = false; };
      };

      shell = {
        enable = lib.mkEnableOption "Shell script hooks (shellcheck, shfmt)" // { default = true; };
        shellcheckExcludes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "\\.envrc$" ];
          description = "Files to exclude from shellcheck";
        };
      };

      just = {
        enable = lib.mkEnableOption "just hooks (just test, just lint)" // { default = false; };
      };
    };
  });

  config.perSystem = { config, pkgs, ... }:
    let
      cfg = config.mccurdyc.pre-commit;
    in
    lib.mkIf cfg.enable {
      # https://flake.parts/options/git-hooks-nix.html
      # usage: pre-commit run <check> --all-files
      pre-commit = {
        check.enable = true;
        settings = {
          tools = {
            inherit (pkgs) just;
          };
          hooks = lib.mkMerge [
            (lib.mkIf cfg.just.enable {
              just-test = {
                enable = true;
                name = "just-test";
                entry = "${pkgs.just}/bin/just test";
                stages = [ "pre-commit" ];
                pass_filenames = false;
              };

              just-lint = {
                enable = true;
                name = "just-lint";
                entry = "${pkgs.just}/bin/just lint";
                stages = [ "pre-commit" ];
                pass_filenames = false;
              };
            })

            (lib.mkIf cfg.nix.enable {
              flake-checker.enable = true;
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              statix.enable = true;
              nil.enable = true;
            })

            (lib.mkIf cfg.rust.enable {
              rustfmt.enable = true;
              cargo-check.enable = true;
              clippy.enable = true;
            })

            (lib.mkIf cfg.shell.enable {
              shellcheck = {
                enable = true;
                excludes = cfg.shell.shellcheckExcludes;
              };
              shfmt = {
                enable = true;
                entry = lib.mkForce "${pkgs.shfmt}/bin/shfmt --simplify --indent 2";
              };
            })
          ];
        };
      };
    };
}
