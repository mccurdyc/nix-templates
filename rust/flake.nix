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

      imports = [
        inputs.rust-flake.flakeModules.default
        inputs.rust-flake.flakeModules.nixpkgs
        inputs.git-hooks.flakeModule

        ./nix/rust.nix
        ./nix/pre-commit.nix
        ./nix/devshell.nix
      ];
    };
}
