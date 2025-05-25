{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # go 1.23.3
    nixpkgs-go.url = "https://github.com/NixOS/nixpkgs/archive/314e12ba369ccdb9b352a4db26ff419f7c49fa84.tar.gz";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixpkgs-go, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
      {
        flake = { };

        systems = [
          "aarch64-darwin"
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
              sha256 = {
                "x86_64-linux" = "1adnf4hb9w0ncpcmvwi2y0k0318zz0xc6zp1sb6x4z50gl9rdfjr";
                "aarch64-darwin" = "12l6ljdc7vjs5b1qygpzi1bacpwbm2fsb9hgan6wf84bickws2yp";
              }.${system};
            };

            ci_packages = {
              cue = pinned_cue;
              inherit (pkgs) curl jq;
              inherit (pkgs-unstable) just; # need just >1.33 for working-directory setting
              yq = pkgs.yq-go;
              inherit (pkgs-go) go; # go 1.23.
            };

            packages = (builtins.attrValues ci_packages) ++ [
              pkgs.statix
              pkgs.nixpkgs-fmt
              pkgs-unstable.nil
            ];
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
                  shfmt = {
                    enable = true;
                    entry = "shfmt --simplify --indent 2";
                  };
                };
              };
            };

            packages = ci_packages;

            devShells.default = pkgs.mkShell {
              inherit (self.checks.${system}.pre-commit-check) shellHook;
              buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
              inherit packages;
            };
          };
      };
}
