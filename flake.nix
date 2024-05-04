{
  # Copied from https://github.com/NixOS/templates/blob/master/flake.nix
  description = "A collection of flake templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # https://nixos.wiki/wiki/Flakes#Output_schema
      flake = {
        templates = {
          minimal = {
            path = ./minimal;
            description = "A very basic flake";
            welcomeText = ''
              # Getting started
              - Run `nix develop`
            '';
          };

          full = {
            path = ./full;
            description = "A comprehensive flake with tools like (pinned) Cue, Kubernetes (things), (pinned) terraform, nix, etc.";
            welcomeText = ''
              # Getting started
              - Run `nix develop`
            '';
          };

          cue = {
            path = ./cue;
            description = "A flake with (pinned) Cue.";
            welcomeText = ''
              # Getting started
              - Run `nix develop`
            '';
          };

          python = {
            path = ./python;
            description = "A flake with python.";
            welcomeText = ''
              # Getting started
              - Run `nix develop`
            '';
          };

          terraform = {
            path = ./terraform;
            description = "A flake with (pinned) Terraform.";
            welcomeText = ''
              # Getting started
              - Run `nix develop`
            '';
          };
        };

        templates.default = self.templates.minimal;
      };

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
            packages = [
              pkgs.statix
              pkgs.nixpkgs-fmt
              pkgs-unstable.nil
            ];
          };
        };
    };
}
