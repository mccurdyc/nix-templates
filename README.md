# nix-templates

Opinionates Nix per-repo flakes.

## Usage

### Forcing the Flake to Update

```bash
nix flake update --flake 'git+ssh://git@github.com/mccurdyc/nix-templates'
```

### From a specific branch

```bash
nix flake init --template 'git+ssh://git@github.com/mccurdyc/nix-templates?ref=main'
```

### Choosing a template

- List templates

```bash
nix flake show
```

- Update existing directory with template

```bash
nix flake init --template 'git+ssh://git@github.com/mccurdyc/nix-templates#full'
```

- Create new directory from template

```bash
nix flake new <target-dir> --template 'git+ssh://git@github.com/mccurdyc/nix-templates#full'
```

### Updating flake

```bash
nix flake update
```

### Updating nixpkgs

```bash
fd \
    --type directory \
    --exact-depth 1 \
    --exec zsh -c "pushd {} && sed -i 's/24.05/24.11/g' flake.nix && sleep 5 && nix flake update"

```

## Design Decisions

- Using flake-parts

Jacek from [Nixcademy](https://nixcademy.com/blog.html) said that he prefers
flake-parts over flake-utils because of it's *"flake composition"*. I haven't
fought enough with either to have a strong preference, so I've opted to trust him.

## Inspiration

- https://github.com/NixOS/templates
- https://github.com/the-nix-way/dev-templates
