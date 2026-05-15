{
  perSystem = { self', pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      inputsFrom = [ self'.devShells.rust ];
      packages = with pkgs; [
        rust-analyzer
        statix
        nixpkgs-fmt
        nil
        deadnix
        gcc
      ];
    };
  };
}
