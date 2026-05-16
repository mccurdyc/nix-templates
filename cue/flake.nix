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

          common = builtins.fetchGit {
            url = "ssh://git@github.com/mccurdyc/playground.git";
            # NOTE: you have to give it a commit for hermetic builds, you CANNOT use a branch name.
            rev = "084060e7894c7e7c83d6491637d7c47a8eb1c83b";
          };

          pinned_cue = pkgs.callPackage "${common}/nix/common/github.nix" {
            inherit system;
            org = "cue-lang";
            name = "cue";
            version = "v0.13.0";
            # 'nix-prefetch-url https://github.com/cue-lang/cue/releases/download/v0.13.0/cue_v0.13.0_darwin_arm64.tar.gz'
            sha256 =
              {
                "x86_64-linux" = "1adnf4hb9w0ncpcmvwi2y0k0318zz0xc6zp1sb6x4z50gl9rdfjr";
                "aarch64-darwin" = "12l6ljdc7vjs5b1qygpzi1bacpwbm2fsb9hgan6wf84bickws2yp";
              }
              .${system};
          };
        in
        {
          mccurdyc = {
            pre-commit.enable = true;
            devshell = {
              extraPackages = [
                pinned_cue
                pkgs.curl
                pkgs.jq
                pkgs-go.go
                pkgs.yq-go
              ];
            };
          };
        };
    };
}
