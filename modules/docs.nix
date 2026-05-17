{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption (_: {
    options.mccurdyc.docs = {
      runbook = {
        enable = lib.mkEnableOption "runbook template" // {
          default = false;
        };
        content = lib.mkOption {
          type = lib.types.lines;
          default = builtins.readFile ./docs/RUNBOOK.md;
          description = "Content for docs/RUNBOOK.md";
        };
      };

      cue = {
        enable = lib.mkEnableOption "Cue patterns doc" // {
          default = false;
        };
        content = lib.mkOption {
          type = lib.types.lines;
          default = builtins.readFile ./docs/cue.md;
          description = "Content for docs/cue.md";
        };
      };

      nix = {
        enable = lib.mkEnableOption "Nix learning notes" // {
          default = false;
        };
        content = lib.mkOption {
          type = lib.types.lines;
          default = builtins.readFile ./docs/nix.md;
          description = "Content for docs/nix.md";
        };
      };
    };
  });
}
