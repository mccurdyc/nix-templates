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
