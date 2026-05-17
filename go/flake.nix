{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # go 1.23.3
    nixpkgs-go.url = "https://github.com/NixOS/nixpkgs/archive/314e12ba369ccdb9b352a4db26ff419f7c49fa84.tar.gz";
    git-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mccurdyc-preferences.url = "github:mccurdyc/nix-templates?dir=modules";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.mccurdyc-preferences.flakeModules.default
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          pkgs-go = import inputs.nixpkgs-go {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          mccurdyc = {
            pre-commit.enable = true;
            devshell = {
              nix.enable = true;
              container.enable = true;
              extraPackages = [
                pkgs-go.go
                pkgs.gotools
                pkgs.go-tools
                pkgs.goimports-reviser
              ];
            };
          };
        };
    };
}
