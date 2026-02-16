# This is a flake-parts perSystem module
#
# Usage in your flake:
#   imports = [ ./nix/modules/dockerfile.nix ];
#
# Configuration example:
#   perSystem.mccurdyc.dockerfile = {
#     enable = true;
#   };
{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption (_: {
    options.mccurdyc.dockerfile = {
      enable = lib.mkEnableOption "dockerfile" // { default = false; };

      baseIgnore = lib.mkOption {
        type = lib.types.lines;
        default = ''
          # Development
          .direnv/
          .envrc
          flake.nix
          flake.lock
          Justfile
          *.md

          # Git
          .git/
          .gitignore

          # IDE
          .vscode/
          .idea/
          *.swp
          *.swo

          # Nix
          result
          result-*

          # Docker
          Dockerfile
          .dockerignore
        '';
        description = "base .dockerignore contents";
      };
      extraIgnore = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "extra .dockerignore contents";
      };
      content = lib.mkOption {
        type = lib.types.lines;
        default = ''
          FROM busybox
        '';
        description = "A dockerfile contents";
      };
    };
  });

  config.perSystem = { config, pkgs, ... }:
    let
      cfg = config.mccurdyc.dockerfile;
    in
    lib.mkIf cfg.enable {
      devShells.dockerfile = pkgs.mkShell {
        shellHook = ''
          # Generate .dockerignore if missing
          if [ ! -f .dockerignore ]; then
            cat > .dockerignore << 'EOF'
          ${cfg.baseIgnore}
          ${cfg.extraIgnore}
          EOF
            echo "Created .dockerignore"
          fi

          # Generate Dockerfile if missing
          if [ ! -f Dockerfile ]; then
            cat > Dockerfile << 'EOF'
          ${cfg.content}
          EOF
            echo "Created Dockerfile"
          fi
        '';
      };
    };
}
