{
  # Copied from https://github.com/NixOS/templates/blob/master/flake.nix
  description = "A collection of flake templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
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

          rust = {
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

          rust-full = {
            path = ./rust-full;
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
            path = ./rust-minimal;
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
            description = "No flake packages.";
            welcomeText = ''
              # Getting started
              - NOTE: If commits / pre-commit-hooks are taking a long time, make sure `.direnv/` is in your .gitignore
              - Run `nix flake update`
              - Run `nix develop`
              - Run `nix build`
              - Run `nix run`
            '';
          };

          asm = {
            path = ./asm;
            description = "No flake packages.";
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
      };

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { config, system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
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
              excludes = [
                "outputs/.*"
                "result/.*"
              ];

              hooks = {
                treefmt = {
                  enable = true;
                  package = config.treefmt.build.wrapper;
                };
              };
            };
          };

          devShells.default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

            packages = with pkgs; [
              nil
              deadnix
              statix
            ];
          };
        };
    };
}
