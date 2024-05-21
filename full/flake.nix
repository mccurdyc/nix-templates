{
  description = "Repo configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # TODO: currently does nothing
      flake = { };

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # This is needed for pkgs-unstable - https://github.com/hercules-ci/flake-parts/discussions/105
      imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

      perSystem = { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.permittedInsecurePackages = [
              # "vault-bin-1.15.6"
            ];
          };
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          # This is needed for pkgs-unstable - https://github.com/hercules-ci/flake-parts/discussions/105
          overlayAttrs = { inherit pkgs-unstable; };

          formatter = pkgs.nixpkgs-fmt;

          # https://github.com/cachix/git-hooks.nix
          # 'nix flake check'
          checks = {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                # Nix
                deadnix.enable = true;
                nixpkgs-fmt.enable = true;
                statix.enable = true;

                # Shell
                shellcheck.enable = true;
                shfmt.enable = true;
              };
            };
          };

          devShells.default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

            # https://github.com/NixOS/nixpkgs/blob/736142a5ae59df3a7fc5137669271183d8d521fd/doc/build-helpers/special/mkshell.section.md?plain=1#L1
            packages =
              let
                pinned_cue = pkgs.callPackage (import ./nix/github.nix) {
                  inherit system;
                  org = "cue-lang";
                  name = "cue";
                  version = "v0.9.0-alpha.4";
                  # https://github.com/NixOS/nixpkgs/blob/54b4bb956f9891b872904abdb632cea85a033ff2/doc/build-helpers/fetchers.chapter.md#update-source-hash-with-the-fake-hash-method
                  sha256 = {
                    # nix-prefetch-url --type sha256 https://github.com/cue-lang/cue/releases/download/v0.9.0-alpha.4/cue_v0.9.0-alpha.4_linux_amd64.tar.gz
                    "x86_64-linux" = "0ks2g9k8hnhjyawhn6hpy6nh4s72l5dbv2h5621vgqhsawdkwd4h";
                    # nix-prefetch-url --type sha256 https://github.com/cue-lang/cue/releases/download/v0.9.0-alpha.4/cue_v0.9.0-alpha.4_darwin_amd64.tar.gz
                    "x86_64-darwin" = "04nnmqlrhww4mfd9m2zxpk1nyfsgdyrkgsjp349lxp971wnxhy5h";
                    # nix-prefetch-url --type sha256 https://github.com/cue-lang/cue/releases/download/v0.9.0-alpha.4/cue_v0.9.0-alpha.4_darwin_arm64.tar.gz
                    "aarch64-darwin" = "1h25wqddrva7n124gfk75v124x398whvh01whvk7bsbrlh15b3jr";
                  }.${system};
                };
                pinned_terraform = pkgs.callPackage (import ./nix/hashicorp.nix) {
                  inherit system;
                  name = "terraform";
                  version = "1.8.2";
                  sha256 = {
                    # nix-prefetch-url --type sha256 https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_linux_amd64.zip
                    "x86_64-linux" = "1k4ag2004bdbv9zjzhcd985l9f69mm90b45yxkh98bg5a50wrwvl";
                    # nix-prefetch-url --type sha256 https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_darwin_amd64.zip
                    "x86_64-darwin" = "08p53xdmh7spqiqdsx14s09n1817yzw2rfzza4caqr5sb8rxl6m7";
                    # nix-prefetch-url --type sha256 https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_darwin_arm64.zip
                    "aarch64-darwin" = "0wsqc25fcg4zcbhmxvkgllzxc8ba1g6c6g95i1p6xv5g3v4z8wgq";
                  }.${system};
                };
                pinned_vault = pkgs.callPackage (import ./nix/hashicorp.nix) {
                  inherit system;
                  name = "vault";
                  version = "1.16.2";
                  sha256 = {
                    # nix-prefetch-url --type sha256 https://releases.hashicorp.com/vault/1.16.2/vault_1.16.2_linux_amd64.zip
                    "x86_64-linux" = "1dxlm21i43p9b5va3rg4v5ddn45pbgvk3dyx9zw79dhcnxif9338";
                    # nix-prefetch-url --type sha256 https://releases.hashicorp.com/vault/1.16.2/vault_1.16.2_darwin_amd64.zip
                    "x86_64-darwin" = "0c8764h012myyzw951d494838adywwaf30i3viwwbv9x4wi6v274";
                    # nix-prefetch-url --type sha256 https://releases.hashicorp.com/vault/1.16.2/vault_1.16.2_darwin_arm64.zip
                    "aarch64-darwin" = "1vmisl3bq5x7l81ddz4b5r2iid0pfxz5yl7sdddy4rrxgrgchnfa";
                  }.${system};
                };
              in
              [
                # General
                pkgs.gnumake
                pkgs.curl
                pkgs.yq-go

                # Cloud
                pkgs.google-cloud-sdk
                pkgs.awscli2
                pkgs.ssm-session-manager-plugin

                # Linters
                pkgs.yamllint

                # Nix
                pkgs.statix
                pkgs.nixpkgs-fmt
                pkgs-unstable.nil

                # Cue
                pkgs-unstable.cuelsp
                pkgs-unstable.cuetools
                pkgs-unstable.nil
                pinned_cue

                # Kubernetes
                pkgs.infra
                pkgs.kubectl
                pkgs.kubernetes-helm
                pkgs.kubie
                pkgs.linkerd
                pkgs.stern
                pkgs.wireguard-go
                pkgs.wireguard-tools

                # Docker
                pkgs.colima
                pkgs.dive
                pkgs.docker
                pkgs.docker-compose

                # HashiCorp
                pinned_terraform
                pkgs.tflint
                pkgs.terraform-ls
                pinned_vault
                # pkgs.vault-bin
              ];
          };
        };
    };
}
