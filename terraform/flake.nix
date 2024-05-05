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
                    # https://nixos.org/manual/nix/stable/command-ref/nix-prefetch-url.html
                    # https://github.com/NixOS/nixpkgs/blob/54b4bb956f9891b872904abdb632cea85a033ff2/doc/build-helpers/fetchers.chapter.md#update-source-hash-with-the-fake-hash-method
                    # "" = pkgs.lib.fakeSha256; # Trust-on-first-use: just do this to get the correct value
                    # nix-prefetch-url --type sha256 https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_darwin_amd64.zip
                    # Add --unpack if using fetchFromGitHub
                    # The result is a base-32 encoded hash, but it works where 'sha256-...' works.
                    "x86_64-linux" = "1k4ag2004bdbv9zjzhcd985l9f69mm90b45yxkh98bg5a50wrwvl";
                    "aarch64-darwin" = "0wsqc25fcg4zcbhmxvkgllzxc8ba1g6c6g95i1p6xv5g3v4z8wgq";
                    "x86_64-darwin" = "08p53xdmh7spqiqdsx14s09n1817yzw2rfzza4caqr5sb8rxl6m7";
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
