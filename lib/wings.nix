{
  buildGoModule,
  lib,
  fetchFromGitHub,
}:

let
  version = "1.0.0-beta26";
in

buildGoModule {
  pname = "wings";
  inherit version;

  src = fetchFromGitHub {
    owner = "pelican-dev";
    repo = "wings";
    rev = "v${version}";
    sha256 = "sha256-Jh/Iga8ymuYhRTzqPjjLPPuE9RtURsOdjEaQOSp+q+M=";
  };

  vendorHash = "sha256-TCTlA+yvfxi0RH0etWJl7B6fbrKVuWZFRFvf7ejrfnA=";

  meta = {
    description = "Wings";
    homepage = "https://pelican.dev/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
