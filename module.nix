{
  lib,
  config,
  pelicanPanelPkg,
  ...
}:
let
  cfg = config.services.pelican-panel;
in
{
  options.services.pelican-panel = {
    enable = lib.mkEnableOption "Pelican Panel service";

    host = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = "What host to bind to";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = "8080";
      description = "What port to bind to";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pelican-panel = {
      enable = cfg.enable;
      description = "Pelican Panel";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pelicanPanelPkg}/bin/pelican-panel";
        Environment = [
          "HOST=${cfg.host}"
          "PORT=${toString cfg.port}"
        ];
      };
    };

    services.phpfpm.pools.pelican-panel = {
      user = "pelican-panel";
      phpPackage = pelicanPanelPkg.php;
    };
  };
}
