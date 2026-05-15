{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = { };

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { config, system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              shfmt = {
                enable = true;
                indent_size = 2;
              };
              deadnix = {
                enable = true;
                no-lambda-arg = true;
              };
              statix.enable = true;
              shellcheck.enable = true;
            };
          };

          # https://github.com/cachix/git-hooks.nix
          # 'nix flake check'
          checks = {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                treefmt = {
                  enable = true;
                  package = config.treefmt.build.wrapper;
                };
              };
            };
          };

          devShells.default = pkgs.mkShell {
            # https://github.com/NixOS/nixpkgs/blob/736142a5ae59df3a7fc5137669271183d8d521fd/doc/build-helpers/special/mkshell.section.md?plain=1#L1
            packages = [
              # needed for numpy
              pkgs.gcc
              pkgs.zlib

              pkgs.python3Full
              pkgs.python3Packages.pip

              # nix
              pkgs.nil
            ];

            shellHook = ''
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
}
