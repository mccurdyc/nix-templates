{
  description = "Repo configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
      {
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


            pinned_cue = pkgs.callPackage (import ./nix/github.nix) {
              inherit system;
              org = "cue-lang";
              name = "cue";
              version = "v0.10.0";
              # 'nix-prefetch-url https://github.com/cue-lang/cue/releases/download/v0.10.0/cue_v0.10.0_darwin_arm64.tar.gz'
              # https://github.com/NixOS/nixpkgs/blob/54b4bb956f9891b872904abdb632cea85a033ff2/doc/build-helpers/fetchers.chapter.md#update-source-hash-with-the-fake-hash-method
              sha256 = {
                "x86_64-linux" = "1liz2gkd0zj72xbg0fynsrcz1rsdqdpfjsgqzwbzv54wyrv9qi4g";
                "aarch64-darwin" = "06k72afvxl0jfa97b8f2b9r7fb7889m0dcqgx2hl6bv8ifp5sbpp";
                "x86_64-darwin" = "13r3nlh8y06735cnzd7qsq1kb8hfc057g5r4yvwfi2jjhyysrmnd";
              }.${system};
            };

            ci_packages = {
              cue = pinned_cue;
              inherit (pkgs) curl jq;
              inherit (pkgs-unstable) just; # need just >1.33 for working-directory setting
              yq = pkgs.yq-go;
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
