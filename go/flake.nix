{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # go 1.23.3
    nixpkgs-go.url = "https://github.com/NixOS/nixpkgs/archive/314e12ba369ccdb9b352a4db26ff419f7c49fa84.tar.gz";
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
          pkgs-go = import inputs.nixpkgs-go {
            inherit system;
            config.allowUnfree = true;
          };

          ci_packages = {
            # General
            inherit (pkgs) just;

            # Go
            inherit (pkgs-go) go; # go 1.23.3
            goimports = pkgs.gotools; # goimports
            staticcheck = pkgs.go-tools; # staticcheck
            inherit (pkgs) goimports-reviser;
          };

          packages = (builtins.attrValues ci_packages) ++ [
            pkgs.nil
            pkgs.hadolint
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
