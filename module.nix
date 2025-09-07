{
  lib,
  config,
  pkgs,
  pelicanPanelPkg,
  ...
}:
let
  cfg = config.services.pelican-panel;
  artisanWrapper = import ./artisan-wrapper.nix {
    inherit pkgs;
    inherit cfg;
  };
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

    runtimeLocation = lib.mkOption {
      type = lib.types.path;
      default = "/srv/http/pelican-panel";
      description = "Path to store the served files";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ artisanWrapper ];

    services.phpfpm.pools.pelican-panel = {
      user = cfg.user;
      group = cfg.group;
      listen = "${cfg.host}:${toString cfg.phpFpmPort}"; # TODO: this is deprecated, how to solve?
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
        root = "${cfg.runtimeLocation}/public";

        locations."/".extraConfig = ''
          index index.php index.html;

          try_files $uri /index.php?$query_string;

          location ~ \.php$ {
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_pass ${cfg.host}:${toString cfg.phpFpmPort};
          }
        '';
      };
    };

    systemd.services.pelican-panel-copy-app = {
      description = "Copy Pelican Panel to a workable directory";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}"
          "${pkgs.rsync}/bin/rsync -a --delete ${pelicanPanelPkg}/share/php/pelican-panel/ ${cfg.runtimeLocation}/"
          "${pkgs.coreutils}/bin/chown -R ${cfg.user}:${cfg.group} ${cfg.runtimeLocation}"
          "${pkgs.coreutils}/bin/chmod -R 755 ${cfg.runtimeLocation}"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
