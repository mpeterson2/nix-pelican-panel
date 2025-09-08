{
  pkgs,
  php,
  lib,
  fetchFromGitHub,
  stdenv,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  npmHooks,
}:

let
  version = "1.0.0-beta25";
  src = fetchFromGitHub {
    owner = "pelican-dev";
    repo = "panel";
    rev = "v${version}";
    sha256 = "sha256-RXtsPYAzz5fZGSq9b8qhbsSYSlz/JazBdEGESN7Cta4=";
  };
  phpOut = import ./pelican-panel-php.nix {
    inherit
      php
      pkgs
      version
      src
      ;
  };
  jsOut = import ./pelican-panel-js.nix {
    inherit
      stdenv
      pkgs
      fetchYarnDeps
      yarnConfigHook
      yarnBuildHook
      nodejs
      npmHooks
      src
      version
      phpOut
      ;
  };
in

pkgs.stdenv.mkDerivation {
  pname = "pelican-panel";
  inherit version src;

  buildInputs = [ pkgs.coreutils ];

  installPhase = ''
    echo ${jsOut}
    echo $(ls ${jsOut})
    echo ${phpOut}
    mkdir -p $out/share/php/pelican-panel/public/build
    cp -r ${phpOut}/share/php/pelican-panel-php/. $out/share/php/pelican-panel
    cp -r ${jsOut}/. $out/share/php/pelican-panel/public/build
  '';

  passthru = {
    php = phpOut.php;
  };

  meta = {
    description = "Pelican Panel";
    homepage = "https://pelican.dev/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
