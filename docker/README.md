# Nix-based Dockerfile

The motivation behind this was to use the same Nix flake for local dependencies
and then in the Docker image that I use for CI.

In practice, I strongly recommend against using this. Mostly for socio-technical reasons.

1. Nix has a very steep learning curves. Probably the most steep that I've ever experienced.
2. You are forcing folks to understand Nix in order to use this approach.
3. There are simpler alternatives for doing this.

## Usage

```bash
docker build -t ci:latest -f Dockerfile.dev .
docker run -v $(pwd):/src --workdir /src ci:latest just --version
just 1.37.0

[mccurdyc@nuc] [nix-templates/docker] [[!?=>] main]
16:15:14 %% just --version
just 1.37.0
```

