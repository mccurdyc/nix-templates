# Reusable Flake-Parts Modules

This directory contains configurable flake-parts modules for use across different
project types. Each module exposes options under `perSystem.mccurdyc.<module>`.

## Modules

### pre-commit.nix

Configures git-hooks.nix with pre-commit hooks for various languages and tools.

**Options:**
- `mccurdyc.pre-commit.enable` (default: `true`) - Enable pre-commit hooks
- `mccurdyc.pre-commit.nix.enable` (default: `true`) - Nix tools
  (flake-checker, deadnix, nixpkgs-fmt, statix, nil)
- `mccurdyc.pre-commit.rust.enable` (default: `false`) - Rust tools (rustfmt,
  cargo-check, clippy)
- `mccurdyc.pre-commit.shell.enable` (default: `true`) - Shell tools
  (shellcheck, shfmt)
- `mccurdyc.pre-commit.shell.shellcheckExcludes` (default: `["\\.envrc$"]`) -
  Files to exclude from shellcheck
- `mccurdyc.pre-commit.just.enable` (default: `false`) - just test/lint hooks

**Example:**
```nix
perSystem.mccurdyc.pre-commit = {
  rust.enable = true;
  just.enable = true;
  shell.shellcheckExcludes = [ "\\.envrc$" "scripts/legacy\\.sh" ];
};
```

### devshell.nix

Provides a configurable development shell with common tools.

**Options:**
- `mccurdyc.devshell.enable` (default: `true`) - Enable development shell
- `mccurdyc.devshell.build.enable` (default: `true`) - Build tools (just)
- `mccurdyc.devshell.nix.enable` (default: `true`) - Nix tools (statix,
  nixpkgs-fmt, nil)
- `mccurdyc.devshell.container.enable` (default: `true`) - Container tools
  (hadolint, dockerfile-language-server, dive)
- `mccurdyc.devshell.rust.enable` (default: `false`) - Include rust-flake
  devShell
- `mccurdyc.devshell.formatter` (default: `pkgs.nixpkgs-fmt`) - Formatter for
  `nix fmt`
- `mccurdyc.devshell.extraPackages` (default: `[]`) - Additional packages
- `mccurdyc.devshell.extraInputsFrom` (default: `[]`) - Additional shells to
  inherit from

**Example:**
```nix
perSystem.mccurdyc.devshell = {
  rust.enable = true;
  container.enable = false;
  extraPackages = [ pkgs.gh pkgs.jq ];
};
```

### rust.nix

Configures rust-flake (crane-based) Rust project builds.

**Options:**
- `mccurdyc.rust.enable` (default: `false`) - Enable Rust project configuration
- `mccurdyc.rust.crateName` (default: `"app"`) - Name of the main crate
- `mccurdyc.rust.craneArgs` (default: `{}`) - Additional crane build arguments

**Example:**
```nix
perSystem.mccurdyc.rust = {
  enable = true;
  crateName = "my-app";
  craneArgs = {
    buildInputs = [ pkgs.openssl ];
    nativeBuildInputs = [ pkgs.pkg-config ];
  };
};
```

## Usage Examples

### Rust Project (current setup)

```nix
{
  imports = [
    inputs.rust-flake.flakeModules.default
    inputs.rust-flake.flakeModules.nixpkgs
    inputs.git-hooks.flakeModule
    ./nix/modules/rust.nix
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    rust.enable = true;

    pre-commit = {
      rust.enable = true;
      just.enable = true;
    };

    devshell.rust.enable = true;
  };
}
```

### Python Project

```nix
{
  imports = [
    inputs.git-hooks.flakeModule
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    pre-commit = {
      nix.enable = true;
      shell.enable = true;
      rust.enable = false;  # Explicitly disable Rust hooks
    };

    devshell = {
      rust.enable = false;
      extraPackages = with pkgs; [ python312 poetry ];
    };
  };
}
```

### Go Project

```nix
{
  imports = [
    inputs.git-hooks.flakeModule
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    pre-commit = {
      rust.enable = false;
      just.enable = true;
    };

    devshell = {
      rust.enable = false;
      container.enable = true;
      extraPackages = with pkgs; [ go gopls golangci-lint ];
    };
  };
}
```

### Minimal Nix-Only Project

```nix
{
  imports = [
    inputs.git-hooks.flakeModule
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    pre-commit.nix.enable = true;  # Only Nix hooks

    devshell = {
      build.enable = false;
      container.enable = false;
      # Only Nix tools in the devshell
    };
  };
}
```

## Disabling Modules

To completely disable a module, set its enable option to false:

```nix
perSystem.mccurdyc = {
  pre-commit.enable = false;  # Disable all pre-commit hooks
  devshell.enable = false;    # Disable the devshell
  rust.enable = false;        # Disable Rust configuration
};
```

## Module Location

These modules can be:
1. **Copied** into each project's `nix/modules/` directory
2. **Symlinked** from a central location
3. **Imported** from a shared flake input
4. **Vendored** via git submodules

For maximum reusability, consider option 3:

```nix
{
  inputs.mccurdyc-modules = {
    url = "github:mccurdyc/nix-modules";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [
    inputs.mccurdyc-modules.flakeModules.pre-commit
    inputs.mccurdyc-modules.flakeModules.devshell
  ];
}
```
