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

        # Local reusable modules
        ./nix/modules/rust.nix
        ./nix/modules/pre-commit.nix
        ./nix/modules/devshell.nix
      ];

      perSystem = {
        mccurdyc = {
          rust.enable = true;

          pre-commit = {
            rust.enable = true;
            just.enable = true;
          };

          devshell.rust.enable = true;
        };
      };
    };
}
