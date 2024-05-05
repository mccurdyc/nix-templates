{ org
, name
, version
, sha256
, system

, lib
, stdenv
, fetchurl
, unzip
, autoPatchelfHook
}:

let
  # Mapping of Nix systems to the GOOS/GOARCH pairs.
  systemMap = {
    x86_64-linux = "linux_amd64";
    i686-linux = "linux_386";
    x86_64-darwin = "darwin_amd64";
    i686-darwin = "darwin_386";
    aarch64-linux = "linux_arm64";
    aarch64-darwin = "darwin_arm64";
  };

  # Get our system
  goSystem = systemMap.${system} or (throw "unsupported system: ${system}");

  # url for downloading composed of all the other stuff we built up.
  url = "https://github.com/${org}/${name}/releases/download/${version}/${name}_${version}_${goSystem}.tar.gz";
in
stdenv.mkDerivation {
  inherit name version;

  # https://ryantm.github.io/nixpkgs/builders/fetchers/
  # https://github.com/NixOS/nixpkgs/blob/0be9c41d543eda69daeb385c2432a60a7127528c/pkgs/build-support/fetchgithub/default.nix
  src = fetchurl { inherit url sha256; };

  # Our source is right where the unzip happens, not in a "src/" directory (default)
  sourceRoot = ".";

  # Stripping breaks darwin Go binaries
  dontStrip = lib.strings.hasPrefix "darwin" goSystem;

  nativeBuildInputs = [ unzip ] ++ (if stdenv.isLinux then [
    # On Linux we need to do this so executables work
    autoPatchelfHook # For running on NixOS for dynamicall-linked paths.
  ] else [ ]);

  installPhase = ''
    mkdir -p $out/bin
    mv ${name}  $out/bin
  '';
}
