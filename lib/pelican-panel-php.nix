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
  vendorHash = "sha256-+nP6J+ZdtWtR4bo8DQkvnS5jVbjvxITnWvwkR+izOYY=";

  php = phpWithExtensions;

  passthru = {
    php = phpWithExtensions;
  };

  meta = {
    description = "Pelican Panel PHP";
  };
}
