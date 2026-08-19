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
  version = "1.0.0-beta36";
  src = fetchFromGitHub {
    owner = "pelican";
    repo = "panel";
    rev = "v${version}";
    sha256 = "sha256-RLeR5oqu+XJpb2IJDSM31t4YFsT+XWK/CWs1l6K5sac=";
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
    mkdir -p $out/share/php/pelican-panel/public/build
    cp -r ${phpOut}/share/php/pelican-panel-php/. $out/share/php/pelican-panel
    cp -r ${jsOut}/. $out/share/php/pelican-panel/public/build
  '';

  passthru = {
    php = phpOut.php;
    inherit phpOut jsOut;
  };

  meta = {
    description = "Pelican Panel";
    homepage = "https://pelican.dev/";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
