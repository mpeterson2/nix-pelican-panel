{
  php,
  pkgs,
  version,
  src,
}:

let
  phpWithExtensions = php.withExtensions (
    exts:
    with exts.all;
    [
      gd
      mysqli
      mbstring
      bcmath
      curl
      zip
      intl
      sqlite3
    ]
    ++ exts.enabled
  );
  pname = "pelican-panel-php";
  composerLock = "$src/composer.lock";
  vendorHash = "sha256-YR7k9u6pToto5VfG5mBeyPemyiCvEX1j/AEiQSIbwWE=";
in

pkgs.php.buildComposerProject {
  inherit pname version src composerLock vendorHash;

  php = phpWithExtensions;

  composerRepository = phpWithExtensions.mkComposerRepository {
    inherit pname version src composerLock vendorHash;
    composer = phpWithExtensions.packages.composer-local-repo-plugin;
    composerNoDev = true;
    composerNoPlugins = true;
    composerNoScripts = true;
    composerStrictValidation = true;
    postPatch = ''
      substituteInPlace composer.json \
        --replace-fail '"preferred-install": "dist"' '"preferred-install": "source"'
    '';
  };

  passthru = {
    php = phpWithExtensions;
  };

  meta = {
    description = "Pelican Panel PHP";
  };
}
