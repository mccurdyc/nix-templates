{
  description = "LaTeX environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

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
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # for building the latex treesitter grammar   (ノ ゜Д゜)ノ ︵ ┻━┻
          nodejs

          python3
          buildLatex

          # nix things
          nil
          deadnix
          statix
          nixpkgs-fmt
        ];
      };

      packages.${system}.default = pkgs.writeShellScriptBin "latex-serve" ''
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
}
