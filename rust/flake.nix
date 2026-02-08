{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";

    flake-parts.url = "github:hercules-ci/flake-parts";
    # rust-flake builds on:
    # - https://github.com/ipetkov/crane
    # - https://github.com/oxalica/rust-overlay
    rust-flake.url = "github:juspay/rust-flake";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];

      # imports are core to how flake-parts evaluates flakeModules perSystem
      imports = [
        # rust-flake proxies rust-overlay and crane modules - https://github.com/juspay/rust-flake/blob/7bb4b549c89bcba9f2c0db3206be282562824655/flake.nix#L22
        # Use `self'` for outputs (the public interface)
        # Use `config` for internal module options (the configuration interface)
        inputs.rust-flake.flakeModules.default
        inputs.rust-flake.flakeModules.nixpkgs
        inputs.git-hooks.flakeModule
      ];

      perSystem = { self', config, pkgs, ... }: {
        rust-project.crates."app".crane.args = {
          # Add any crate-specific build dependencies here
        };

        # https://flake.parts/options/git-hooks-nix.html
        # available fields - https://flake.parts/options/git-hooks-nix.html#opt-perSystem.pre-commit.settings.hooks._name_.enable
        # usage:
        #   pre-commit run <check> --all-files
        pre-commit = {
          check.enable = true;
          settings.hooks = {
            just-test = {
              enable = true;
              name = "just-test";
              entry = "just test";
              stages = [ "pre-commit" ];
              pass_filenames = false;
            };

            just-lint = {
              enable = true;
              name = "just-lint";
              entry = "just lint";
              stages = [ "pre-commit" ];
              pass_filenames = false;
            };

            # Nix
            flake-checker.enable = true;
            deadnix.enable = true;
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            nil.enable = true;

            # Rust
            rustfmt.enable = true;
            cargo-check.enable = true;
            clippy.enable = true;

            # Shell
            shellcheck = {
              enable = true;
              # exclude exactly .envrc anywhere
              excludes = [ "\\.envrc$" ];
              # or only check *.sh files
              # files = "\\.sh$";
            };
            shfmt = {
              enable = true;
              entry = "shfmt --simplify --indent 2";
            };
          };
        };

        formatter = pkgs.nixpkgs-fmt;

        # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
        # nix eval '.#devShells.<system>.default'
        # nix eval '.#devShells.$(nix eval --impure --raw --expr builtins.currentSystem).default'
        devShells.default = pkgs.mkShell {
          inputsFrom = [
            # output visibility, not evaluation timing. Both modules are fully evaluated;
            # they just expose their results differently.
            self'.devShells.rust
            config.pre-commit.devShell # https://github.com/cachix/git-hooks.nix/blob/a8ca480175326551d6c4121498316261cbb5b260/flake-module.nix#L81
          ];
          packages = [
            pkgs.just
            pkgs.statix
            pkgs.nixpkgs-fmt
            pkgs.nil
            pkgs.hadolint
            pkgs.dockerfile-language-server
            pkgs.dive
          ];
        };
      };
    };
}
