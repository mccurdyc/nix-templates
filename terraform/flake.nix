{
  description = "Repo configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, flake-parts, pre-commit-hooks, ... }:
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
                terraform_1_8_2

                pkgs.gnumake

                # nix
                pkgs.statix
                pkgs.nixpkgs-fmt
                pkgs-unstable.nil
              ];
          };
        };
    };
}
