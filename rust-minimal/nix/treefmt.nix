{
  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt.enable = true;
        rustfmt.enable = true;
        shfmt.enable = true;
      };
    };
  };
}
