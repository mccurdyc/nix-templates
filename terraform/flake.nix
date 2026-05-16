{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
          common = builtins.fetchGit {
            url = "ssh://git@github.com/mccurdyc/playground.git";
            # NOTE: you have to give it a commit for hermetic builds, you CANNOT use a branch name.
            rev = "59b48e2674d1998d9f7b316a8eab990a0edd8f37";
          };

          pinned_terraform = pkgs.callPackage "${common}/nix/hashicorp.nix" {
            inherit system;
            name = "terraform";
            version = "1.8.2";
            sha256 =
              {
                # nix-prefetch-url --type sha256 https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_linux_amd64.zip
                "x86_64-linux" = "1k4ag2004bdbv9zjzhcd985l9f69mm90b45yxkh98bg5a50wrwvl";
                "aarch64-darwin" = "0wsqc25fcg4zcbhmxvkgllzxc8ba1g6c6g95i1p6xv5g3v4z8wgq";
              }
              .${system};
          };
        in
        {
          mccurdyc = {
            pre-commit.enable = true;
            devshell = {
              extraPackages = [
                pinned_terraform
                pkgs.tflint
                pkgs.terraform-ls
              ];
            };
          };
        };
    };
}
