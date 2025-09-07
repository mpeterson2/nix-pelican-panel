{
  lib,
  fetchFromGitHub,
  php,
}:
let
  version = "1.0.0-beta25";
  phpWithExtensions = php.withExtensions (
    { enabled, all }:
    with all;
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
    ++ enabled
  );
in
php.buildComposerProject {
  pname = "pelican-panel";
  inherit version;

  src = fetchFromGitHub {
    owner = "pelican-dev";
    repo = "panel";
    rev = "v${version}";
    sha256 = "sha256-RXtsPYAzz5fZGSq9b8qhbsSYSlz/JazBdEGESN7Cta4=";
  };

  composerLock = "$src/composer.lock";

  vendorHash = "sha256-Be1OOHeWClnXpimtjwMmN8Z9fc4BWqwpjfx1mPln5Zg=";

  php = phpWithExtensions;

  passthru = {
    php = phpWithExtensions;
  };

  meta = with lib; {
    description = "Pelican Panel";
    homepage = "https://pelican.dev/";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
  };
}
