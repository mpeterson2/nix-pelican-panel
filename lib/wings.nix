{
  buildGoModule,
  lib,
  fetchFromGitHub,
}:

let
  version = "1.0.0-beta17";
in

buildGoModule {
  pname = "wings";
  inherit version;

  src = fetchFromGitHub {
    owner = "pelican-dev";
    repo = "wings";
    rev = "v${version}";
    sha256 = "sha256-trQZk101Z/TvLHP0xEVm4yWyKjAcwHo1Z5aLM4kmgkU=";
  };

  vendorHash = "sha256-bPsoneaYHcOi57S1/U8FvCefTqSMMswqrC+SLW3Q2OQ=";

  meta = {
    description = "Wings";
    homepage = "https://pelican.dev/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
