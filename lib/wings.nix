{
  buildGoModule,
  lib,
  fetchFromGitHub,
}:

let
  version = "1.0.0-beta25";
in

buildGoModule {
  pname = "wings";
  inherit version;

  src = fetchFromGitHub {
    owner = "pelican-dev";
    repo = "wings";
    rev = "v${version}";
    sha256 = "sha256-EFWK8VYYMw1rU7ktAdEL7XRO3dFYW/2hPgOlsfWInHA=";
  };

  vendorHash = "";

  meta = {
    description = "Wings";
    homepage = "https://pelican.dev/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
