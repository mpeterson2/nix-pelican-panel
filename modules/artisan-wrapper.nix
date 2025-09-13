{ pkgs, cfg }:

pkgs.writeShellScriptBin "pelican-panel-artisan" ''
  #!/bin/sh
  exec ${pkgs.php}/bin/php ${cfg.runtimeLocation}/artisan "$@"
''
