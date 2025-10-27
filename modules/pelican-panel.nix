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
      description = "The host Pelican Panel will listen on.";
      default = "0.0.0.0";
      type = lib.types.str;
    };

    port = lib.mkOption {
      description = "The port the web server will listen on.";
      default = 8080;
      type = lib.types.int;
    };

    phpfpm = lib.mkOption {
      description = "Config for Phpfpm.";
      default = { };
      type = lib.types.submodule {
        options = {
          poolName = lib.mkOption {
            type = lib.types.str;
            default = "pelican-panel";
            description = "The pool name the PHP FMP run as.";
          };
        };
      };
    };

    user = lib.mkOption {
      description = "The user Pelican Panel should run as.";
      default = "pelican-panel";
      type = lib.types.str;
    };

    group = lib.mkOption {
      description = "The group Pelican Panel should run as.";
      default = "pelican-panel";
      type = lib.types.str;
    };

    openFirewall = lib.mkOption {
      description = "Whether to open the Pelican Panel port in the firewall.";
      default = true;
      type = lib.types.bool;
    };

    runtimeLocation = lib.mkOption {
      description = "Path to store the served files";
      default = "/srv/http/pelican-panel";
      type = lib.types.path;
    };

    nginx = lib.mkOption {
      description = "Config for Nginx";
      default = { };
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable Nginx.";

          enableACME = lib.mkEnableOption "Enable ACME. Define your ACME config before enabling.";
          addSSL = lib.mkEnableOption "Enable SSL.";
          forceSSL = lib.mkEnableOption "Force SSL.";

          sslCertificate = lib.mkOption {
            description = "SSL certificate.";
            default = null;
            type = lib.types.nullOr lib.types.str;
          };

          sslCertificateKey = lib.mkOption {
            description = "SSL certificate key.";
            default = null;
            type = lib.types.nullOr lib.types.str;
          };

          virtualHost = lib.mkOption {
            description = "Virtual host for Nginx.";
            default = "pelican-panel";
            type = lib.types.str;
          };

          extraConfig = lib.mkOption {
            description = "Extra configuration for the server block.";
            default = "";
            type = lib.types.str;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ artisanWrapper ];

    services.phpfpm.pools."${cfg.phpfpm.poolName}" = {
      user = cfg.user;
      group = cfg.group;
      phpPackage = pelicanPanelPkg.php;

      settings = {
        "listen.owner" = config.services.nginx.user;
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.max_requests" = 500;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 5;
      };
    };

    services.nginx = lib.mkIf cfg.nginx.enable {
      enable = cfg.nginx.enable;

      virtualHosts.${cfg.nginx.virtualHost} = {
        enableACME = cfg.nginx.enableACME;
        addSSL = cfg.nginx.addSSL;
        forceSSL = cfg.nginx.forceSSL;
        sslCertificate = cfg.nginx.sslCertificate;
        sslCertificateKey = cfg.nginx.sslCertificateKey;

        listen = [
          {
            addr = cfg.host;
            port = cfg.port;
          }
        ];
        root = "${cfg.runtimeLocation}/public";

        locations."/".extraConfig = ''
          index index.php index.html;
          try_files $uri $uri/ /index.php?$query_string;
        '';

        locations."~ \.php$".extraConfig = ''
          include ${pkgs.nginx}/conf/fastcgi.conf;
          fastcgi_pass unix:${config.services.phpfpm.pools.${cfg.phpfpm.poolName}.socket};
        '';

        extraConfig = cfg.nginx.extraConfig;
      };
    };

    systemd.services.pelican-panel-deploy = {
      description = "Deploy Pelican Panel";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}/bootstrap/cache"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}/storage/app/private"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}/storage/app/public"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}/storage/framework/cache"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}/storage/framework/sessions"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}/storage/framework/testing"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}/storage/framework/views"
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.runtimeLocation}/storage/logs"
          ''
            ${pkgs.rsync}/bin/rsync -a --delete \
            --exclude='.env' \
            --exclude='storage' \
            --exclude='bootstrap/cache' \
            --exclude='database/database.sqlite' \
            ${pelicanPanelPkg}/share/php/pelican-panel/ \
            ${cfg.runtimeLocation}/
          ''
          "${pkgs.coreutils}/bin/chown -R ${cfg.user}:${cfg.group} ${cfg.runtimeLocation}"
          "${pkgs.coreutils}/bin/chmod -R 755 ${cfg.runtimeLocation}"
        ];
        RemainAfterExit = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.pelican-panel-queue = {
      description = "Pelican Panel queue worker";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.php}/bin/php ${cfg.runtimeLocation}/artisan queue:work --sleep=3 --tries=3";
        User = cfg.user;
        WorkingDirectory = cfg.runtimeLocation;
        Restart = "always";
        RestartSec = 5;
      };
    };

    systemd.services.pelican-panel-schedule = {
      description = "Run Pelican Panel schedule";
      serviceConfig = {
        ExecStart = "${pkgs.php}/bin/php ${cfg.runtimeLocation}/artisan schedule:run";
        User = cfg.user;
        WorkingDirectory = cfg.runtimeLocation;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.timers.pelican-panel-schedule = {
      description = "Run Pelican Panel schedule every minute";
      timerConfig = {
        OnUnitActiveSec = "1m";
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
