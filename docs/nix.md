# Installation

- https://zero-to-nix.com/

# Introduction

- Why Nix?
	- 10y cache
	- "sandbox"
	- Deterministic and declarative (configuration as code)
	- Common build tooling and dependencies manager wrapper for all languages
		- Don't need `package.lock` or `pip`, etc
	- Atomic upgrades / rollbacks
		- Just linux symlinks
	- Configuration state versions
- What do you struggle with / dislike most / or would change about nix?
	- community split on flakes
	- new commands vs old commands
	- few things on flakes
- Preferring per-project configurations over global packages, etc

# Installation
- Installing
	- determinate sys installer should be preferred
		- Not a massive bash script, it's rust
		- Easier to uninstall
		- https://determinate.systems/posts/lessons-from-1-million-nix-installs 

# Commands
- `nix repl --file '<nixpkgs>'` is really useful. Have an alias for this
	- `:b <package>` builds derivation and prints output paths
	- `pkgs.ripgrep`
	- `:b pkgs.ripgrep`
	- `:?`
	- `nix `
- `nix profile` - global packages
	- upgrade all `nix profile upgrade ".*"`
		- dont do this.
- `nix-shell -p hello --pure`
	- Dont install other "useful" packages
	- specific version of hello
	- `nix shell github:nixos/nixpkgs/nixos-22.05#hello`

# Nix build basics
- `.nix > .drv > /nix/store/<hash>-<name>`
- `nix-build <.../foo.drv>` then `/result/bin`
- derivation
	- no dynamic parts
	- no variables
	- .drv is sent to the nix daemon via the socket
- `<hash>`
	- source code, compiler, build system, envs, etc....
- `$(nix-build ...)/bin/foo`
- `<nixpkgs>` is looked up from `NIX_PATH`
- Could differ from machine to machine
- `(repl) <nixpkgs>`

# nixpkg pinning
```
$ cat nixpkgs.nix
builtins.fetchTarball {
url = "https://github.com/nixos/nixpkgs/archive/bd4e35e14a0130268c8f7b253a15e09d76ec95b7.tar.gz";
sha256 = "0k9ffj84mq21w17jfdh0rcr9pcvnbmaq9y3r7yd9k1mvry708cq5";
}
```

```
$ nix repl
nix-repl> nixpkgsSrc = import ./nixpkgs.nix
nix-repl> pkgs = import nixpkgsSrc {}
```

# building software via nix
- `stdenv.mkDerivation` MAGIC!! for configuring and installing
- `configure` scripts is passed with `--prefix` and pointed at `$out` so that it installs to the appropriate path instead of `/usr/local/bin`.
	- This is in the `configurePhase`
	- `buildPhase` just runs `make`
	- `installPhase` runs `make install`
	- `checkPhase` runs `make check`
	- `fixupPhase` strips symbols 

- `propagatedBuildInputs` for non-compiled languages (e.g., python, etc)

- https://nixos.org/manual/nixpkgs/stable/#ssec-patch-phase

- Where is `stdenv.mkDerivation` defined in nixpkgs?
	- https://github.com/NixOS/nixpkgs/blob/f80b2b510db9b02e98fb2ba1042b755543c852cf/pkgs/stdenv/generic/make-derivation.nix#L108 
	- in nixpkgs `find . -name "builder.sh"` to debug 
		- `./pkgs/stdenv/generic/builder.sh`
		- `./pkgs/stdenv/generic/setup.sh` <----
			- `patchPhase`, etc. - defined in here
- trivial-builders
	- wrappers around `mkDerivation`
	- `nixpkgs/pkgs/build-support/trivial-builders/default.nix`
		- `mkShell` is in here!!
		- `writeShellApplication`
			- Define dependencies
			- Runs shellcheck at build time
			- installable as a binary!!
		- `symlinkJoin`
			- Adds bins to out
			- Would love to see a deeper dive into `symlinkJoin 2/2` example as intro to the class 
			- Same with `python` dependency example
- python
	- Could instead use poetry2nix
```
let
  pkgs = import <nixpkgs > { };
in
  pkgs. python3Packages.buildPythonPackage rec {
    pname = " mypackage ";
    version = "1.0.0";
    src = fetchPypi {
      inherit pname version;
      sha256 = "08f... ef0 ";
    };
    doCheck = false;
}
```
- Go
	- `buildGoModule`
- Rust
	- https://crane.dev - nix library not part of nixpkgs

# overrides
```
pkgs.hello.override { stdenv = clangStdenv; }
# change compiler from gcc to clangStdenv
# ldd ./result/bin/hello
```

```
pkgs.hello.overrideAttrs (old: { patchPhase = "sed -i 's/Hello, world!/Bye/' src/hello.c"; doCheck = false; })

# patched hello with different compiler
(pkgs.hello.overrideAttrs (old: { patchPhase = "sed -i 's/Hello, world!/Bye' src/hello.c"; doCheck = false; })).override {stdenv = pkgs.clangStdenv; }
```

```
# same as overrideAttrs
pkgs.callPackage ./hello.nix {stdenv = pkgs.clangStdenv; }
```

- `override` overrides params to `callPackage`
- `overrideAttrs` overrides params to `mkDerivation`
- `callPackage` with `override` is super powerful.
- `callPackageWith`

# Project structure / Examples
- https://galowicz.de/2023/01/23/mixed-cpp-monorepo-project/
- https://github.com/tfc/meson_cpp_example
- https://github.com/tfc/pprintpp
- https://galowicz.de/2023/01/16/cpp-qt-qml-nix-setup/
- https://galowicz.de/2019/04/17/tutorial_nix_cpp_setup/
- https://github.com/cyberus-technology/hedron
	- He specifically showed this one
	- [Building for cartesian product of outputs](https://github.com/cyberus-technology/hedron/blob/8ab6bd0bd6468be4602f65280a58ced1b1999156/nix/release.nix#L43-L73) rather than 30 different docker images
```
builtins.map (str: "${str}-foo") ["a" "b" "c"]
builtins.map (str: pkgs.lib.nameValuePair "${str}-key" {value = str; }) [ "a" "b" "c"]
```
```
:p builtins.map (str: pkgs.lib.nameValuePair "${str}-key" {value = str; }) [ [ { name = "a-key"; value = { value = "a"; }; } { name = "b-key"; value = { value = "b"; }; } { name = "c-key"; value = { value = "c"; }; } 
```
- https://github.com/tfc/pandoc-drawio-filter
- https://github.com/tfc/electron-purescript-example

# fetching source
- trust on first use
- OR;
```
# hash local file before uploading / don't need `pkgs.lib.fakeSha256`
nix hash to-sri --sha256 \
 $(nix-unpack-url --unpack file:///.../myfile.tar.gz)
```
- `fetchzip` (any tarball format, not just zip)

# derivation

- `$out` is a nix store path
	- hash of the inputs 
- learning about a nix pkg in `nix repl`
	- `pkgs.<foo>`  - he used this a lot
	- `${pkgs.<foo>}` - prints the nix store path
- `nix-build default.nix` or `nix-build` if you are using `default.nix`
- `nix-instantiate`
	- `cat /nix/store /<foo>.drv`
	- `nix show-derivation /nix/store/<foo>.drv` or `nix show-derivation $(nix-instantiate)`
	- `nix-build $(nix-instantiate)`
- Getting all dependencies
		- (see below)
- All parameters to your derivation become ENVs in your derivation
	- This is for communicating with your builder function
- `readlink $(which ls)`
- Uses linux namespaces as the build "sandboxes". Just like docker containers
- https://nixos.org/manual/nixpkgs/stable/#sec-stdenv-phases
- https://nixos.org/manual/nix/stable/language/derivations.html#derivations
- dynamic patching a derivation
	- `substitute` or `sustituteInPlace` or `substituteAll` functions
	- https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-functions
- Shebangs
	- no `/usr/bin/...` in the nix sandbox
	- `/usr/bin/env xxx` works if `xxx` is part of scripts in the install phase, it automatically patches
```
buildPhase = ''
	patchShebangs ./scripts/
	./scripts/foo.sh
'';
```

# overlays

- "global overrides"
- order matters
- They do fix-point recursion
	- I.e., keep recursing until nothing changes anymore
	- I.e., until the package tree doesnt change anymore
	- `pkgs.lib.fix`
		- Keep in mind nix is lazy
	- `self:` refers to the last version of self
- patching deps of multiple packages
	- `app1.override`, `app2.override`, `app3.override` this sucks
```
pksg.fix f (self: {x=1, y = self.x}
# infinite recurision
```
- `final`, `prev` (used to be `self`, `super`)
	- Why `final`?
		- patching in overlay1
- overlays could be used to patch a CVE globally
- combining overlays `pkgs.lib.composeExtensions` and `pkgs.lib.composeManyExtensions` return a single overlay

# Dependencies
```
nix-store --query --tree <path>
nix-store --query --tree $(nix-build . -A pkgs.hello # 
nix-store --query --tree $(nix-instantiate . -A pkgs.hello)
nix why-depends <package> <dep>
```
- nix-build (small) - compile-time dependencies
- nix-instantiate (large) - build-time dependencies (compilers, etc.)
- nix-build --keep-failed
	- debugging builder, etc. 
- NIX_DEBUG=1 in derivations attrs
- `pkgs.breakPointHook` can dump you into the build linux container / namespace
	- or `nix-build --keep-failed ...`
# Patterns / Antipatterns
- Avoid `with` except `with pkgs; [...]`
	- It hides a lot. Where do symbols come from?
	- performance penalty too!
		- Has to evaluate all key names
- Avoid `rec`
- Avoid default nixpkgs selection in function params
	- overuse of "implicit singletons"
- Only use `callPackage` for derivations
	- Don't just use `callPackage` because it allows you to not define input params

# Source filtering
- `pkgs.lib.sources.<autocomplete>` in the repl
- `src = ./.;` includes `result/` and generates a new hash for each `nix-build` call
- More cache hits
	- Fewer rebuilds
- `pkgs.lib.cleanSource`
	- Drops .git, .o, etc. files
	- `src = lib.cleanSource ./.;`
- `pkgs.lib.sourceFilesBySuffices`
- `pkgs.lib.sourceByRegex`
	- only copy files matching regex
- If you need tons of filtering, it's probably a sniff of bad project structure. You shouldn't need many filters.
- debugging filters
	- `pkgs.lib.sources.trace(pkgs.lib.sources.<filter>...)`

# cross-system compilation
- `crossSystem` param to `nixpkgs`
	- Mostly tooling, envs, cmake, changing `configure` script, etc.
	- Not really changing the sandbox
```
pkgs = import <nixpkgs> {};
armPkgs = import <nixpkgs> {crossSystem = pkgs.lib.systems.examples.aarch64-multiplatform; };
armPkgs.curl
```
- `pkgs.pkgsCross.<arch>`  
- Look at `nixpkgs/pkgs/top-level/stage.nix` and `nipkgs/pkgs/stdenv/adapters.nix` for source of cross compilation
- https://ryantm.github.io/nixpkgs/stdenv/cross-compilation/
- build systems are usually the cause of not being able to cross-compile
# Nix library
- tools are limited
- READ THESE 80-90% of all you will need to read `nixpkgs/lib/{attrsets,lists,customisation}.nix`
	- You will learn purely functional patterns
	- "Dont re-invent the wheel"
- https://noogle.dev/
	- search for functions from `builtins` or `pkgs.lib`
	- Similar to Go pkgs
```
forEach :: [a] -> (a -> b) -> [b]
# takes a list of a, converts to b via a function and returns b
```

# flakes
- Flakes are polarizing
	- Why?
	- You don't need flakes
- https://nixos.wiki/wiki/Flakes#Output_schema
- cached evaluations!
- "evaluation closure"
- hermetic evaluation (no NIX_PATH, etc)
- no channels / instead registry on github
- "experimental"
	- it's not technically stable, but pretty much is because they dont want to break large companies depending on it
- each project should export overlays for other projects to consume
	- but you could also use flakes in your project
- Purely a "frontend thing"
	- The daemon doesnt know anything about flakes
	- Derivations are for the daemon
- `outputs`
	- function
	- `nix flake show`
		- prints the result set
	- `nix build`
	- `nix build '.#hello'`
- `nixpkgs.legacyPackages...`  
	- nixpkgs before our flake
	- not some old legacy meaning of packages
	- Similar to `prev` for overlays
- `self.packages...` 
	- After 
- `nix -L develop`
	- Gets package dependencies while `nix shell` only gets the package (w/o deps)
- `"missing attributes currentSystem"`
	- `builtins.currentSystem` is explicitly disabled in flakes
	- Wanted flakes to evaluate the same on all systems
- He prefers flake-parts over flake-utils
	- flake compositions
- `nix run github:tfc/heise-nix#hello-rust`
	- WOW!!!
	- This has to pull and build the source
		- This is where cachix comes into play - https://www.cachix.org/ 
		- The daemon would check the cache server before building from source
- `nixosModules` - importable NixOS modules
	- Re-usable things e.g., Terraform modules
- `nixosConfigurations` - whole system nixos configs
	- `--target root@host` 
- `nix flake check`
	- "Cheap CI"
	- Checks 
	- Builds all derivations as part of the check phase

# shells
- you can run `unpackPhase`, `configurePhase` right in here
- devenv
	- simplified environment for creating a build shell for your environment
	- For folks who dont care about nix, just want yaml, etc
		- Not ready to invest in nix
		- But you could move to "real nix" from this. It's a good migration path
	- Makes it easy to spawn a container env (`devenv up`)
		- Not a devenv feature, you could do this in raw nix
	- What he doesnt like?
		- Doesnt do more than nix, just a simpler interface

# pre-commit hooks
- `nix flake -L check`

# NixOS
- [Armijn Hemel's NixCon Brno 2019 talk](https://www.youtube.com/watch?v=fsgYVi2PQr0&pp=ygUXaGFybWFuIG5peG9zIG1lcmt5IHBhc3Q%3D) (i didn't get much from this talk)
- Installation
	1. boot live system
		- setup network
	2. partition, format and mount disk
	3. create initial system config
		- `nixos-generate-config`
	4. install
		- `nixos-install`
		- generates top-level closure
		- runs install script of top-level closure
- configuration.nix is just a nixos module
- https://nixcademy.com/2023/09/04/nixos-multi-php-version-container/
- nixos-anywhere - https://github.com/nix-community/nixos-anywhere
- disko flake / module for formatting and mounting nixos
	- https://github.com/nix-community/disko
	- removes the need for manual partitioning
- `nixos-rebuild build --flake '.#'`
	- `/result` contains the top-level
- `nix run github:nix-community/nixos-anywhere -- root@<ip> --flake .#<name>`
	- You do need the disko stuff configured properly
- `nixos-rebuild switch --flake .#<name> --target-host root@<ip> --use-substitutes`
	- `--use-substitutes` tell it to fetch from the nix cache itself rather than copying file
- GitHub.com/tfc/nixos-anywhere-example

## NixOS Integration Tests
- `nixpkgs/nixos/tests/bittorrent.nix`
	- best example of nixos tests
	- `tracker` - nixos config

# nixery - small docker images
- https://nixery.dev/
- https://github.com/tazjin/nixery
- flakyfied
	- https://github.com/tfc/nixery
	- also has flake-parts
- Good example of Go with nix

# Go Example
- https://github.com/tfc/nixery

# Rust Example
- https://github.com/tfc/rust_async_http_code_experiment
	- Uses crane.dev
	- precommit checks
	- example of transitive dependencies on openssl

# Optionals
`pkgs.lib.optionalAttrs <bool> {}`
`stdenv.isLinux`

# Debugging
- no "step by step" debugger
- no control flow; it is data flow language
```
builtins.trace 
	"val: ${builtins.toString x}"
	(x+x) # the expression to trace
```

# Random learning
- `pkgs.makeWrapper` - useful for appending flags, etc. to a binary, etc.
	- best docs are `nixpkgs/pkgs/build-support/setup-hooks/make-wrapper.sh`
- https://plantuml.com/ - textual diagrams similar to mermaid or whatever 
	- https://github.com/plantuml/plantuml
- `echo $PATH | tr ':' '\n'`
- `nom` - https://github.com/maralorn/nix-output-monitor
	- drop-in replacement for `nix`
- https://lapbench.com/

# Resources

## NixOS

### Official
<a name="nixos-official"></a>

- https://nixos.org/manual/nixos/stable/
- https://search.nixos.org/options
	- Searching configuration options
- https://nixos.org/manual/nixos/stable/options
	- Configuration options

### Unofficial
<a name="nixos-unofficial"></a>
<!--- Blogs, etc. -->

---

## Nixpkgs

### Official
<a name="nixpkgs-official"></a>
- https://nixos.org/manual/nixpkgs/stable/
- https://search.nixos.org/packages

### Unofficial
<a name="nixpkgs-unofficial"></a>
<!--- Blogs, etc. -->

---

## Nix

### Official
<a name="nix-official"></a>
- https://nixos.org/manual/nix/stable/

### Unofficial
<a name="nix-unofficial"></a>
<!--- Blogs, etc. -->

---

## Nix-Darwin

### Official
<a name="darwin-official"></a>
- https://daiderd.com/nix-darwin/manual/index.html
	- Configuration options

### Unofficial
<a name="darwin-unofficial"></a>
<!--- Blogs, etc. -->

---

## Home-manager

### Official
<a name="homemanager-official"></a>
- https://nix-community.github.io/home-manager/
	- Different section for standalone, nix-darwin and nixos.
	- Different section for ^^, but with flakes!
- https://nix-community.github.io/home-manager/options.html
	- Configuration options

### Unofficial
<a name="homemanager-unofficial"></a>
<!--- Blogs, etc. -->

- TODO

---

## Other semi-official sites
<a name="semi-official"></a>

- https://zero-to-nix.com/
- https://nix.dev/
- https://nixos.wiki/

## Other useful blogs
<a name="other-blogs"></a>
- https://nixcademy.com/blog.html
