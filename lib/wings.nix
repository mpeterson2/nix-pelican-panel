{
  buildGoModule,
  lib,
  fetchFromGitHub,
}:

let
  version = "1.0.0-beta24";
in

buildGoModule {
  pname = "wings";
  inherit version;

  src = fetchFromGitHub {
    owner = "pelican-dev";
    repo = "wings";
    rev = "v${version}";
    sha256 = "";
  };

  vendorHash = "sha256-MveNLXINvxAjJOG9nvXgfSxnEUkHI0Bnqxmgg/0Qu6Q=";

  meta = {
    description = "Wings";
    homepage = "https://pelican.dev/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
