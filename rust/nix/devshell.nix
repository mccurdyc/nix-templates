# Development shell configuration for this specific project
{
  perSystem = { self', config, pkgs, ... }: {
    formatter = pkgs.nixpkgs-fmt;

    # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
    devShells.default = pkgs.mkShell {
      inputsFrom = [
        self'.devShells.rust
        config.pre-commit.devShell
      ];

      packages = with pkgs; [
        # Build tools
        just

        # Nix tools
        statix
        nixpkgs-fmt
        nil

        # Container tools
        hadolint
        dockerfile-language-server
        dive
      ];
    };
  };
}
