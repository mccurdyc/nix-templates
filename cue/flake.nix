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
                  sha256 = {
                    # https://nixos.org/manual/nix/stable/command-ref/nix-prefetch-url.html
                    # https://github.com/NixOS/nixpkgs/blob/54b4bb956f9891b872904abdb632cea85a033ff2/doc/build-helpers/fetchers.chapter.md#update-source-hash-with-the-fake-hash-method
                    # "" = pkgs.lib.fakeSha256; # Trust-on-first-use: just do this to get the correct value
                    # 'nix-prefetch-url --type sha256 https://github.com/cue-lang/cue/releases/download/v0.9.0-alpha.4/cue_v0.9.0-alpha.4_darwin_arm64.tar.gz'
                    # Add --unpack if using fetchFromGitHub
                    # The result is a base-32 encoded hash, but it works where 'sha256-...' works.
                    "x86_64-linux" = "0ks2g9k8hnhjyawhn6hpy6nh4s72l5dbv2h5621vgqhsawdkwd4h";
                    "aarch64-darwin" = "1h25wqddrva7n124gfk75v124x398whvh01whvk7bsbrlh15b3jr";
                    "x86_64-darwin" = "04nnmqlrhww4mfd9m2zxpk1nyfsgdyrkgsjp349lxp971wnxhy5h";
                  }.${system};
                };
              in
              [
                pkgs-unstable.cuelsp
                pkgs-unstable.cuetools
                pkgs-unstable.nil
                cue_0_9_0_alpha4

                pkgs.gnumake
                pkgs.kubernetes-helm
                pkgs.nixpkgs-fmt
                pkgs.statix
                pkgs.yamllint
              ];
          };
        };
    };
}
