# Pre-commit hooks configuration for this specific project
{
  perSystem = _: {
    # https://flake.parts/options/git-hooks-nix.html
    # usage: pre-commit run <check> --all-files
    pre-commit = {
      check.enable = true;
      settings.hooks = {
        # Nix hooks
        flake-checker.enable = true;
        deadnix.enable = true;
        nixpkgs-fmt.enable = true;
        statix.enable = true;
        nil.enable = true;

        # Rust hooks
        rustfmt.enable = true;

        # Shell hooks
        shellcheck = {
          enable = true;
          excludes = [ "\\.envrc$" ];
        };
        shfmt.enable = true;
      };
    };
  };
}
