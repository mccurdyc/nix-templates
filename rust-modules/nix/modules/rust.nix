# Rust project configuration module
#
# This is a flake-parts perSystem module that configures rust-flake
# (crane-based Rust builds) for a standard Rust project.
#
# Usage in your flake:
#   imports = [ ./nix/modules/rust.nix ];
#
# Configuration example:
#   perSystem.mccurdyc.rust = {
#     enable = true;
#     crateName = "my-app";
#     craneArgs = {
#       buildInputs = [ pkgs.openssl ];
#       nativeBuildInputs = [ pkgs.pkg-config ];
#     };
#   };
{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption (_: {
    options.mccurdyc.rust = {
      enable = lib.mkEnableOption "Rust project configuration" // { default = false; };

      crateName = lib.mkOption {
        type = lib.types.str;
        default = "app";
        description = "Name of the main crate to build";
      };

      craneArgs = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional crane build arguments (buildInputs, nativeBuildInputs, etc.)";
        example = lib.literalExpression ''
          {
            buildInputs = [ pkgs.openssl ];
            nativeBuildInputs = [ pkgs.pkg-config ];
          }
        '';
      };
    };
  });

  config.perSystem = { config, ... }:
    let
      cfg = config.mccurdyc.rust;
    in
    lib.mkIf cfg.enable {
      rust-project.crates.${cfg.crateName}.crane.args = cfg.craneArgs;
    };
}
