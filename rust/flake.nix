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
    # mccurdyc-preferences.url = "path:../modules";
    mccurdyc-preferences.url = "github:mccurdyc/nix-templates?dir=modules";
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

          dockerfile = {
            enable = true;
            extraIgnore = ''
              target/
            '';
            content = ''
              # syntax=docker/dockerfile:1
              FROM lukemathwalker/cargo-chef:latest-rust-1.87-alpine AS chef
              WORKDIR /app

              FROM chef AS planner
              COPY . .
              RUN cargo chef prepare --recipe-path recipe.json

              FROM chef AS builder
              COPY --from=planner /app/recipe.json recipe.json
              # Build dependencies - this is the caching Docker layer!
              RUN cargo chef cook --release --recipe-path recipe.json
              # Build application
              COPY . .
              RUN cargo build --release --bin app

              FROM alpine:3.20 AS runtime
              RUN apk add --no-cache ca-certificates \
                  && addgroup -g 1000 app \
                  && adduser -D -s /bin/sh -u 1000 -G app app
              WORKDIR /app
              COPY --from=builder /app/target/release/app /app/app
              USER app
              ENTRYPOINT ["/app/app"]
              CMD ["greet"]
            '';
          };
        };
      };
    };
}
