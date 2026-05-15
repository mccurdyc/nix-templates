{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = { };

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { config, system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pinned_cue = pkgs.callPackage (import ./nix/github.nix) {
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

          ci_packages = {
            cue = pinned_cue;
            inherit (pkgs) curl jq;
            inherit (pkgs) just;
            yq = pkgs.yq-go;
          };

          packages = (builtins.attrValues ci_packages) ++ [
            pkgs.nil
          ];
        in
        {
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              shfmt = {
                enable = true;
                indent_size = 2;
              };
              deadnix = {
                enable = true;
                no-lambda-arg = true;
              };
              statix.enable = true;
              shellcheck.enable = true;
            };
          };

          # https://github.com/cachix/git-hooks.nix
          # 'nix flake check'
          checks = {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                treefmt = {
                  enable = true;
                  package = config.treefmt.build.wrapper;
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
