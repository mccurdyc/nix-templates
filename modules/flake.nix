{
  description = "Flake-parts modules for development environments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      flake = {
        flakeModules = {
          devshell = ./devshell.nix;
          docs = ./docs.nix;
          pre-commit = ./pre-commit.nix;
          rust = ./rust.nix;
          treefmt = ./treefmt.nix;
          default = {
            imports = [
              ./devshell.nix
              ./docs.nix
              ./dockerfile.nix
              ./rust.nix
            ];
          };
        };
      };

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt;
        };
    };
}
