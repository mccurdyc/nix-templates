# Pre-commit hooks configuration module
#
# This is a flake-parts perSystem module that provides configurable git-hooks.nix
# (pre-commit hooks) for various project types.
#
# In a monorepo, set `rootDir` to the path of the subdirectory containing this
# flake (relative to the git root). All hooks will be scoped to that directory:
# - pass_filenames=false hooks (just, cargo-*) cd into rootDir before running
# - pass_filenames=true hooks (nix, shell) restrict matched files to rootDir
#
# Usage in your flake:
#   imports = [ ./nix/modules/pre-commit.nix ];
#
# Configuration example:
#   perSystem.mccurdyc.pre-commit = {
#     enable = true;
#     rootDir = "rust/machine-code";
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

      rootDir = lib.mkOption {
        type = lib.types.str;
        default = ".";
        description = ''
          Path to the project root relative to the git repository root.
          Used in monorepos to scope hooks to a subdirectory. Hooks that
          receive filenames will only match files under this path; hooks
          that do not receive filenames will cd into this directory first.
        '';
      };

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

      # Wraps a command so it runs from rootDir. Used for hooks where
      # pass_filenames = false (i.e. they act on the whole project).
      cdEntry = cmd:
        if cfg.rootDir == "."
        then cmd
        else "bash -c 'cd ${lib.escapeShellArg cfg.rootDir} && ${cmd}'";

      # Regex that restricts file-based hooks to rootDir. An unset rootDir
      # ("." ) means no restriction.
      scopedFiles = suffix:
        if cfg.rootDir == "."
        then suffix
        else "^${lib.escapeRegex cfg.rootDir}/${suffix}";
    in
    lib.mkIf cfg.enable {
      # https://flake.parts/options/git-hooks-nix.html
      # usage: pre-commit run <check> --all-files
      #
      # check.enable runs all hooks inside the nix sandbox via `nix flake check`.
      # Hooks that invoke build tools (cargo, just) cannot run in the sandbox --
      # those are validated by their own crane/rust-flake check derivations.
      # Only enable the nix check when no build-tool hook groups are active.
      pre-commit = {
        check.enable = !(cfg.rust.enable || cfg.just.enable);
        settings = {
          tools = {
            inherit (pkgs) just;
          };
          hooks = lib.mkMerge [
            (lib.mkIf cfg.just.enable {
              just-test = {
                enable = true;
                name = "just-test";
                entry = cdEntry "${pkgs.just}/bin/just test";
                stages = [ "pre-commit" ];
                pass_filenames = false;
              };

              just-lint = {
                enable = true;
                name = "just-lint";
                entry = cdEntry "${pkgs.just}/bin/just lint";
                stages = [ "pre-commit" ];
                pass_filenames = false;
              };
            })

            (lib.mkIf cfg.nix.enable {
              flake-checker = {
                enable = true;
                files = scopedFiles ".*\\.nix$";
              };
              deadnix = {
                enable = true;
                files = scopedFiles ".*\\.nix$";
              };
              nixpkgs-fmt = {
                enable = true;
                files = scopedFiles ".*\\.nix$";
              };
              statix = {
                enable = true;
                files = scopedFiles ".*\\.nix$";
              };
              nil = {
                enable = true;
                files = scopedFiles ".*\\.nix$";
              };
            })

            (lib.mkIf cfg.rust.enable {
              rustfmt = {
                enable = true;
                files = scopedFiles ".*\\.rs$";
              };
              cargo-check = {
                enable = true;
                entry = cdEntry "cargo check";
                files = scopedFiles ".*\\.rs$";
                pass_filenames = false;
              };
              clippy = {
                enable = true;
                entry = cdEntry "cargo clippy";
                files = scopedFiles ".*\\.rs$";
                pass_filenames = false;
              };
            })

            (lib.mkIf cfg.shell.enable {
              shellcheck = {
                enable = true;
                files = scopedFiles ".*\\.sh$";
                excludes = cfg.shell.shellcheckExcludes;
              };
              shfmt = {
                enable = true;
                files = scopedFiles ".*\\.sh$";
                entry = lib.mkForce "${pkgs.shfmt}/bin/shfmt --simplify --indent 2";
              };
            })
          ];
        };
      };
    };
}
