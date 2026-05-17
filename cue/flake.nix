{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # https://www.nixhub.io/packages/go
    # go 1.26.2
    nixpkgs-go.url = "https://github.com/NixOS/nixpkgs/archive/01fbdeef22b76df85ea168fbfe1bfd9e63681b30.tar.gz";
    # cue 0.16.1
    nixpkgs-cue.url = "https://github.com/NixOS/nixpkgs/archive/01fbdeef22b76df85ea168fbfe1bfd9e63681b30.tar.gz";
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
          pkgs-cue = import inputs.nixpkgs-cue {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          mccurdyc = {
            docs.cue.enable = true;
            pre-commit.enable = true;
            devshell = {
              extraPackages = [
                pkgs-go.go
                pkgs-cue.cue
                pkgs.curl
                pkgs.jq
                pkgs.yq-go
              ];
            };
          };
        };
    };
}
