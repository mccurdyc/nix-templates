{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mccurdyc-preferences.url = "github:mccurdyc/nix-templates?dir=modules";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.mccurdyc-preferences.flakeModules.default
      ];

      perSystem =
        { pkgs, ... }:
        {
          mccurdyc = {
            pre-commit.enable = true;
            devshell = {
              extraPackages = [
                pkgs.gcc
                pkgs.zlib
                pkgs.python3Full
                pkgs.python3Packages.pip
              ];
              extraShellHook = ''
                # Why? - I don't want to use virtualenvs to manage environments. I want to use Nix.
                # Tells pip to put packages into $PIP_PREFIX instead of the usual locations.
                # See https://pip.pypa.io/en/stable/user_guide/#environment-variables.
                export PIP_PREFIX=$(pwd)/_build/pip_packages
                export PYTHONPATH="$PIP_PREFIX/${pkgs.python3Full.sitePackages}"
                export LD_LIBRARY_PATH="${pkgs.zlib}/lib:${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
                export PATH="$PIP_PREFIX/bin:$PATH"
                unset SOURCE_DATE_EPOCH

                pip3 install -r requirements.txt
              '';
            };
          };
        };
    };
}
