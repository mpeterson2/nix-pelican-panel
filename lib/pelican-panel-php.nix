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
  vendorHash = "sha256-OwJ6FSvRW4P8JscatMWSzVUok8M3zy5RhltM71Vyh6k=";
in

pkgs.php.buildComposerProject {
  inherit pname version src composerLock vendorHash;

  php = phpWithExtensions;

  passthru = {
    php = phpWithExtensions;
  };

  meta = {
    description = "Pelican Panel PHP";
  };
}
