{
  description = "Flake-parts modules for development environments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      flake = {
        flakeModules = {
          devshell = ./devshell.nix;
          pre-commit = ./pre-commit.nix;
          default = {
            imports = [
              ./devshell.nix
              ./pre-commit.nix
              ./dockerfile.nix
            ];
          };
        };
      };

      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;
      };
    };
}
