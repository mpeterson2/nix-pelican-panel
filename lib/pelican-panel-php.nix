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
in

pkgs.php.buildComposerProject {
  pname = "pelican-panel-php";
  inherit version;
  inherit src;

  composerLock = "$src/composer.lock";
  vendorHash = "sha256-Be1OOHeWClnXpimtjwMmN8Z9fc4BWqwpjfx1mPln5Zg=";

  php = phpWithExtensions;

  passthru = {
    php = phpWithExtensions;
  };

  meta = {
    description = "Pelican Panel PHP";
  };
}
