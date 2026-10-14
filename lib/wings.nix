{
  buildGoModule,
  lib,
  fetchFromGitHub,
}:

let
  version = "1.0.0-rc.1";
in

buildGoModule {
  pname = "wings";
  inherit version;

  src = fetchFromGitHub {
    owner = "pelican";
    repo = "wings";
    rev = "v${version}";
    sha256 = "sha256-TErlxIXSlmxPaEQLLqcHUm+Sum+pjI8hYve0CWpc6hc=";
  };

  vendorHash = "sha256-2Hs1SfCsf5JYIIRC0VHlfVzRx2e+xrSotqrfbCqMogo=";

  meta = {
    description = "Wings";
    homepage = "https://pelican.dev/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
