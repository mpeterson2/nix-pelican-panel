{
  stdenv,
  pkgs,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  npmHooks,
  src,
  version,
  phpOut,
}:

let
  original = builtins.fromJSON (builtins.readFile (src + "/package.json"));
  patched = original // {
    name = "pelican-panel-js";
    version = version;
  };
  packageJSON = pkgs.writeText "package.json" (builtins.toJSON patched);
in

stdenv.mkDerivation (finalAttrs: {
  pname = "pelican-panel-js";
  inherit src version;

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-VLero9gHqkh6svauRSwZf2ASpEBu9iQcPUx+J77SR+o=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    nodejs
    npmHooks.npmInstallHook
  ];

  dontNpmPrune = true;

  buildPhase = ''
    cp ${packageJSON} package.json
    cp -r ${phpOut}/share/php/pelican-panel-php/vendor/. ./vendor
    yarn build
  '';

  installPhase = ''
    cp -r public/build $out
  '';
})
