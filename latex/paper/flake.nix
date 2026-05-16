{
  description = "LaTeX environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mccurdyc-preferences.url = "github:mccurdyc/nix-templates?dir=modules";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.mccurdyc-preferences.flakeModules.default
      ];

      perSystem =
        { pkgs, ... }:
        let
          texlive = pkgs.texlive.combined.scheme-full;

          buildLatex = pkgs.writeShellScriptBin "build-latex" ''
            if [ -z "$1" ]; then
              echo "Usage: build-latex <filename.tex>"
              exit 1
            fi
            echo "Running pdflatex (pass 1)..."
            ${texlive}/bin/pdflatex -interaction=nonstopmode "$1"

            # Extract basename without extension
            BASENAME="''${1%.tex}"

            # Run bibtex if .aux file exists
            if [ -f "$BASENAME.aux" ]; then
              echo "Running bibtex..."
              ${texlive}/bin/bibtex "$BASENAME" || true
            fi

            echo "Running pdflatex (pass 2)..."
            ${texlive}/bin/pdflatex -interaction=nonstopmode "$1"

            echo "Running pdflatex (pass 3)..."
            ${texlive}/bin/pdflatex -interaction=nonstopmode "$1"

            echo "Build complete: $BASENAME.pdf"
          '';
        in
        {
          mccurdyc = {
            pre-commit.enable = true;
            devshell = {
              extraPackages = [
                pkgs.nodejs
                pkgs.python3
                buildLatex
              ];
            };
          };

          packages.default = pkgs.writeShellScriptBin "latex-serve" ''
            set -e

            # Cleanup function
            cleanup() {
              echo "Stopping services..."
              kill $LATEXMK_PID $SERVER_PID 2>/dev/null || true
            }
            trap cleanup EXIT INT TERM

            # Build and watch with latexmk
            echo "Building PDF with latexmk and watching for changes..."
            ${texlive}/bin/latexmk -pdf -pvc -interaction=nonstopmode main.tex &
            LATEXMK_PID=$!

            echo "Serving on http://localhost:8000/main.pdf"
            echo "Press Ctrl+C to stop"
            ${pkgs.python3}/bin/python3 -m http.server 8000 &
            SERVER_PID=$!
            wait
          '';
        };
    };
}
