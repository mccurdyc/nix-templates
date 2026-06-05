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

### treefmt.nix

Configures treefmt-nix formatters based on the
`mccurdyc.pre-commit` option groups. Requires
`treefmt-nix.flakeModule` to be imported alongside this module.

No additional options -- reuses
`mccurdyc.pre-commit.{nix,shell,rust}.enable` to determine which
formatters to activate.

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

## Module Composition

The `default` flakeModule includes: `devshell`, `docs`, `rust`, and
`dockerfile`. It does **not** include `pre-commit` or `treefmt`
because those require upstream flake module imports
(`git-hooks-nix.flakeModule` and `treefmt-nix.flakeModule`
respectively).

### Required Upstream Dependencies

Consumers must declare these upstream flake inputs for the
corresponding modules to work:

| Dependency | URL | Required by |
|---|---|---|
| `git-hooks-nix` | `github:cachix/git-hooks.nix` | `pre-commit` |
| `treefmt-nix` | `github:numtide/treefmt-nix` | `treefmt` |
| `rust-flake` | `github:juspay/rust-flake` | `rust` (when enabled) |

Input names are your choice -- the examples below use these
names, but adjust to match your `inputs` block.

To use pre-commit and treefmt, import them explicitly alongside
their dependencies:

```nix
imports = [
  inputs.nix-templates.flakeModules.default    # devshell, docs, rust, dockerfile
  inputs.nix-templates.flakeModules.pre-commit # requires git-hooks-nix
  inputs.nix-templates.flakeModules.treefmt    # requires treefmt-nix
  inputs.git-hooks-nix.flakeModule
  inputs.treefmt-nix.flakeModule
];
```

Flakes that don't need pre-commit or treefmt simply omit those
imports.

## Usage Examples

### Rust Project

```nix
{
  imports = [
    inputs.nix-templates.flakeModules.default
    inputs.nix-templates.flakeModules.pre-commit
    inputs.nix-templates.flakeModules.treefmt
    inputs.rust-flake.flakeModules.default
    inputs.rust-flake.flakeModules.nixpkgs
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
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
    inputs.nix-templates.flakeModules.default
    inputs.nix-templates.flakeModules.pre-commit
    inputs.nix-templates.flakeModules.treefmt
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem.mccurdyc.devshell.extraPackages =
    with pkgs; [ python312 poetry ];
}
```

### Go Project

```nix
{
  imports = [
    inputs.nix-templates.flakeModules.default
    inputs.nix-templates.flakeModules.pre-commit
    inputs.nix-templates.flakeModules.treefmt
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem.mccurdyc = {
    pre-commit.just.enable = true;

    devshell = {
      container.enable = true;
      extraPackages =
        with pkgs; [ go gopls golangci-lint ];
    };
  };
}
```

### Minimal Nix-Only Project

```nix
{
  imports = [
    inputs.nix-templates.flakeModules.default
    inputs.nix-templates.flakeModules.pre-commit
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem.mccurdyc.devshell = {
    build.enable = false;
    container.enable = false;
  };
}
```

## Disabling Modules

`pre-commit` and `treefmt` are disabled by not importing them (see
Module Composition above).

For modules included in `default`, set enable to false:

```nix
perSystem.mccurdyc = {
  devshell.enable = false;
  rust.enable = false;
};
```

## Module Location

Import from the `nix-templates` flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-templates = {
      url = "github:mccurdyc/nix-templates?dir=modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = [
    inputs.nix-templates.flakeModules.default
    inputs.nix-templates.flakeModules.pre-commit
    inputs.nix-templates.flakeModules.treefmt
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];
}
```
