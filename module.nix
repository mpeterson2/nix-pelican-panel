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
      default = "0.0.0.0";
      description = "The host pelican panel will listen on.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 8080;
      description = "The port the web server will listen on.";
    };

    phpFpmPort = lib.mkOption {
      type = lib.types.int;
      default = 9000;
      description = "The port the PHP FMP will listen on.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "pelican-panel";
      description = "The user pelican panel should run as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "pelican-panel";
      description = "The group pelican panel should run as.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open the pelican panel port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.phpfpm.pools.pelican-panel = {
      user = cfg.user;
      group = cfg.group;
      listen = "${cfg.host}:${toString cfg.phpFpmPort}";
      phpPackage = pelicanPanelPkg.php;

      settings = {
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.max_requests" = 500;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 5;
      };
    };

    services.nginx = {
      enable = true;

      virtualHosts."pelican-panel" = {
        listen = [
          {
            addr = cfg.host;
            port = cfg.port;
          }
        ];
        root = "${pelicanPanelPkg}/share/php/pelican-panel/public";
        locations."/".extraConfig = ''
          try_files $uri /index.php?$query_string;
        '';
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
