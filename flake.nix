{
  # Copied from https://github.com/NixOS/templates/blob/master/flake.nix
  description = "A collection of flake templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # https://nixos.wiki/wiki/Flakes#Output_schema
      flake = {
        templates = {
          minimal = {
            path = ./minimal;
            description = "A very basic flake";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
            '';
          };

          docker = {
            path = ./docker;
            description = "A flake with a Dockerfile";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
            '';
          };

          full = {
            path = ./full;
            description = "A comprehensive flake with tools like (pinned) Cue, Kubernetes (things), (pinned) terraform, nix, etc.";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
            '';
          };

          go = {
            path = ./go;
            description = "A Go flake.";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
            '';
          };

          rust-starter = {
            path = ./rust;
            description = "A Rust flake";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
              - Run `nix build`
              - Run `nix run`
            '';
          };

          rust-minimal = {
            path = ./rust;
            description = "A Rust flake";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
              - Run `nix build`
              - Run `nix run`
            '';
          };

          cue = {
            path = ./cue;
            description = "A flake with (pinned) Cue.";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
            '';
          };

          python = {
            path = ./python;
            description = "A flake with python.";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
            '';
          };

          terraform = {
            path = ./terraform;
            description = "A flake with (pinned) Terraform.";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
            '';
          };

          latex-paper = {
            path = ./latex/paper;
            description = "LaTeX for a paper.";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix run`
            '';
          };

          latex-slides = {
            path = ./latex/slides;
            description = "LaTeX for slides.";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix run`
            '';
          };

          bare = {
            path = ./bare;
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
              - Run `nix build`
              - Run `nix run`
            '';
          };
        };

        templates.default = self.templates.bare;
      };

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
              # These excludes apply for nix flake check.[web:15]
              excludes = [
                "outputs/.*"
                "result/.*"
              ];

              hooks = {
                # Nix
                deadnix = {
                  enable = true;
                  # These settings are passed to deadnix itself.[web:15]
                  settings = {
                    exclude = [
                      "outputs"
                      "result"
                    ];
                    noLambdaArg = true;
                  };
                };
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
