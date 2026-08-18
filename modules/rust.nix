# Rust project configuration module
#
# Higher-level module that configures a Rust development environment
# by orchestrating the lower-level mccurdyc.{devshell,dockerfile} modules.
# Pre-commit hooks for Rust are configured by importing flakeModules.pre-commit
# and setting mccurdyc.pre-commit.rust.enable = true separately.
#
# Usage:
#   perSystem.mccurdyc.rust = {
#     enable = true;
#     just.enable = true;
#     container.enable = true;
#   };
{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption (_: {
    options.rust-project = {
      toolchain = lib.mkOption {
        type = lib.types.package;
        description = "Rust toolchain package. Automatically set by rust-flake; otherwise set manually when using a custom Rust toolchain.";
      };
    };

    options.mccurdyc.rust = {
      enable = lib.mkEnableOption "Rust development environment" // {
        default = false;
      };

      just = {
        enable = lib.mkEnableOption "just build tool and pre-commit hooks" // {
          default = false;
        };
      };

      container = {
        enable = lib.mkEnableOption "container support (Dockerfile generation, container tools)" // {
          default = false;
        };

        extraIgnore = lib.mkOption {
          type = lib.types.lines;
          default = ''
            target/
          '';
          description = "Extra .dockerignore entries for Rust projects.";
        };

        dockerfile = lib.mkOption {
          type = lib.types.lines;
          default = ''
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
            RUN apk add --no-cache just
            RUN just build

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
          description = "Dockerfile content for Rust projects.";
        };
      };
    };
  });

  config.perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.mccurdyc.rust;
    in
    lib.mkIf cfg.enable {
      mccurdyc = {
        devshell = {
          extraPackages = [
            pkgs.rust-analyzer
            config.rust-project.toolchain
          ];
          container.enable = cfg.container.enable;
        };

        dockerfile = lib.mkIf cfg.container.enable {
          enable = true;
          extraIgnore = cfg.container.extraIgnore;
          content = cfg.container.dockerfile;
        };
      };
    };
}
