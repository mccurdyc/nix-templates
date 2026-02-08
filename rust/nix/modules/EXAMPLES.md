# Configuration Examples

## Quick Reference

### Default Values

When you import a module without configuration, these are the defaults:

```nix
perSystem.mccurdyc = {
  # pre-commit.nix defaults
  pre-commit = {
    enable = true;           # pre-commit is enabled
    nix.enable = true;       # Nix hooks enabled
    rust.enable = false;     # Rust hooks disabled
    shell.enable = true;     # Shell hooks enabled
    just.enable = false;     # just hooks disabled
  };

  # devshell.nix defaults
  devshell = {
    enable = true;           # devshell is enabled
    build.enable = true;     # includes just
    nix.enable = true;       # includes statix, nixpkgs-fmt, nil
    container.enable = true; # includes hadolint, dive, etc.
    rust.enable = false;     # does not include rust-flake devShell
  };

  # rust.nix defaults
  rust = {
    enable = false;          # Rust project disabled
    crateName = "app";       # default crate name
    craneArgs = {};          # no extra build args
  };
};
```

## Project-Specific Examples

### 1. Rust Project (Minimal)

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
    pre-commit.rust.enable = true;
    devshell.rust.enable = true;
  };
}
```

### 2. Rust Project (with custom dependencies)

```nix
perSystem.mccurdyc = {
  rust = {
    enable = true;
    crateName = "my-service";
    craneArgs = {
      buildInputs = with pkgs; [ openssl ];
      nativeBuildInputs = with pkgs; [ pkg-config ];
    };
  };

  pre-commit = {
    rust.enable = true;
    just.enable = true;
  };

  devshell = {
    rust.enable = true;
    extraPackages = with pkgs; [ sqlx-cli ];
  };
};
```

### 3. Python Project

```nix
{
  imports = [
    inputs.git-hooks.flakeModule
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    devshell.extraPackages = with pkgs; [
      python312
      poetry
      python312Packages.pytest
      python312Packages.black
      python312Packages.ruff
    ];
  };
}
```

### 4. Go Project

```nix
{
  imports = [
    inputs.git-hooks.flakeModule
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    devshell = {
      container.enable = true;  # Keep container tools for Docker builds
      extraPackages = with pkgs; [
        go
        gopls
        golangci-lint
        delve
      ];
    };
  };
}
```

### 5. TypeScript/Node Project

```nix
{
  imports = [
    inputs.git-hooks.flakeModule
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    pre-commit = {
      shell.enable = true;  # for shell scripts
    };

    devshell = {
      container.enable = false;
      extraPackages = with pkgs; [
        nodejs_20
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.prettier
        nodePackages.eslint
      ];
    };
  };
}
```

### 6. Documentation/Writing Project

```nix
{
  imports = [
    inputs.git-hooks.flakeModule
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    pre-commit = {
      nix.enable = true;     # Keep Nix checks for flake
      shell.enable = false;  # No shell scripts
    };

    devshell = {
      build.enable = false;
      container.enable = false;
      extraPackages = with pkgs; [
        mdbook
        hugo
        marksman  # Markdown LSP
      ];
    };
  };
}
```

### 7. Multi-Language Monorepo

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
    rust = {
      enable = true;
      crateName = "backend";
    };

    pre-commit = {
      rust.enable = true;
      shell.enable = true;
      just.enable = true;
    };

    devshell = {
      rust.enable = true;
      container.enable = true;
      extraPackages = with pkgs; [
        # Frontend
        nodejs_20
        nodePackages.typescript

        # Database
        postgresql
        sqlx-cli

        # Observability
        docker-compose
      ];
    };
  };
}
```

### 8. Nix-Only Project (no code)

```nix
{
  imports = [
    inputs.git-hooks.flakeModule
    ./nix/modules/pre-commit.nix
    ./nix/modules/devshell.nix
  ];

  perSystem.mccurdyc = {
    # All defaults are fine - just Nix tools
    # Or explicitly:
    devshell = {
      build.enable = false;
      container.enable = false;
      # Only Nix tools will be included
    };
  };
}
```

## Advanced Patterns

### Override pre-commit for specific files

```nix
perSystem = { config, ... }: {
  mccurdyc.pre-commit = {
    rust.enable = true;
    shell.shellcheckExcludes = [
      "\\.envrc$"
      "scripts/legacy/.*\\.sh$"
      "vendor/.*"
    ];
  };

  # Direct override for more control
  pre-commit.settings.hooks.rustfmt.excludes = [ "generated/.*" ];
};
```

### Multiple formatters

```nix
perSystem = { pkgs, ... }: {
  mccurdyc.devshell.formatter = pkgs.alejandra;  # Use alejandra instead
};
```

### Conditional configuration based on system

```nix
perSystem = { system, pkgs, ... }: {
  mccurdyc.devshell.extraPackages =
    if system == "x86_64-linux" then
      [ pkgs.linuxPackages.perf ]
    else
      [ ];
};
```

### Disable everything (manual control)

```nix
perSystem.mccurdyc = {
  pre-commit.enable = false;
  devshell.enable = false;
  rust.enable = false;
};

# Then configure manually in perSystem
perSystem = { pkgs, ... }: {
  devShells.default = pkgs.mkShell {
    packages = [ pkgs.hello ];
  };
};
```
