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
              "vault-bin-1.15.6"
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
                cue_0_9_0_alpha4 = pkgs.callPackage (import ./nix/github.nix) {
                  inherit system;
                  org = "cue-lang";
                  name = "cue";
                  version = "v0.9.0-alpha.4";
                  # 'nix-prefetch-url https://github.com/cue-lang/cue/releases/download/v0.9.0-alpha.4/cue_v0.9.0-alpha.4_darwin_arm64.tar.gz'
                  # https://github.com/NixOS/nixpkgs/blob/54b4bb956f9891b872904abdb632cea85a033ff2/doc/build-helpers/fetchers.chapter.md#update-source-hash-with-the-fake-hash-method
                  sha256 = {
                    # "" = pkgs.lib.fakeSha256; # Trust-on-first-use: just do this to get the correct value
                    "x86_64-linux" = pkgs.lib.fakeSha256;
                    "aarch64-darwin" = "sha256-WY5VAqR56XXmhjwAuCFHaXQiwi5nukdEsEft3BrmRcA=";
                    "x86_64-darwin" = pkgs.lib.fakeSha256;
                  }.${system};
                };
                terraform_1_8_2 = pkgs.callPackage (import ./nix/hashicorp.nix) {
                  inherit system;
                  name = "terraform";
                  version = "1.8.2";
                  sha256 = {
                    "x86_64-linux" = pkgs.lib.fakeSha256; # Trust-on-first-use: just do this to get the correct value
                    # "aarch64-darwin" = pkgs.lib.fakeSha256; # Trust-on-first-use: just do this to get the correct value
                    "aarch64-darwin" = "sha256-+HH0yR6v7G5uiCU9w8wLaiHWP6Vv7l7hYp885opgWHM="; # Trust-on-first-use: just do this to get the correct value
                    "x86_64-darwin" = pkgs.lib.fakeSha256; # Trust-on-first-use: just do this to get the correct value
                  }.${system};
                };
              in
              [
                # General
                pkgs.gnumake
                pkgs.curl
                pkgs.yq-go

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
                cue_0_9_0_alpha4

                # Kubernetes
                pkgs.infra
                pkgs.kubectl
                pkgs.kubernetes-helm
                pkgs.kubie
                pkgs.linkerd
                pkgs.stern
                pkgs.vault-bin
                pkgs.wireguard-go
                pkgs.wireguard-tools

                # Docker
                pkgs.colima
                pkgs.dive
                pkgs.docker
                pkgs.docker-compose

                # Terraform
                terraform_1_8_2
              ];
          };
        };
    };
}
