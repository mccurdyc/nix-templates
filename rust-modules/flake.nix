{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";

    flake-parts.url = "github:hercules-ci/flake-parts";
    # rust-flake builds on:
    # - https://github.com/ipetkov/crane
    # - https://github.com/oxalica/rust-overlay
    rust-flake.url = "github:juspay/rust-flake";

    # personal preferences
    mccurdyc-preferences.url = "path:../modules";
    # mccurdyc-preferences.url = "github:mccurdyc/nix-templates?dir=modules";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];

      # imports are core to how flake-parts evaluates flakeModules perSystem
      imports = [
        inputs.git-hooks.flakeModule
        inputs.mccurdyc-preferences.flakeModules.default
      ];

      perSystem = _: {
        mccurdyc = {
          pre-commit = {
            enable = true;
            rust.enable = true;
            just.enable = true;
          };

          devshell = {
            extraPackages = [ ];
          };
        };
      };
    };
}
