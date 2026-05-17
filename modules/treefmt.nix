# Treefmt configuration module
#
# Provides a unified formatter via treefmt-nix, configured based on the
# mccurdyc.pre-commit option groups (nix, shell, rust).
#
# Consumers must import inputs.treefmt-nix.flakeModule alongside this module.
{
  flake-parts-lib,
  ...
}:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    # No new options — reuses mccurdyc.pre-commit.{nix,shell,rust}.enable
  });

  config.perSystem =
    {
      config,
      options,
      lib,
      ...
    }:
    let
      cfg = config.mccurdyc.pre-commit;
      hasTreefmt = options ? treefmt;
    in
    lib.mkIf (hasTreefmt && cfg.enable) {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = lib.mkMerge [
          (lib.mkIf cfg.nix.enable {
            nixfmt.enable = true;
            deadnix = {
              enable = true;
              no-lambda-arg = true;
            };
            statix.enable = true;
          })

          (lib.mkIf cfg.shell.enable {
            shellcheck.enable = true;
            shfmt = {
              enable = true;
              indent_size = 2;
            };
          })

          (lib.mkIf cfg.rust.enable {
            rustfmt.enable = true;
          })
        ];
        settings = lib.mkIf cfg.shell.enable {
          formatter.shellcheck.excludes = [ ".envrc" ];
        };
      };
    };
}
