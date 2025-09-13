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

    phpfpm = lib.mkOption {
      type = lib.types.submodule {
        options = {
          poolName = lib.mkOption {
            type = lib.types.str;
            default = "pelican-panel";
            description = "The pool name the PHP FMP run as.";
          };
        };
      };
      default = { };
      description = "Config for Phpfpm.";
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

    nginx = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable Nginx.";

          virtualHost = lib.mkOption {
            type = lib.types.str;
            default = "pelican-panel";
            description = "Virtual host for Nginx.";
          };
        };
      };
      default = { };
      description = "Config for Nginx";
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
          ''
            ${pkgs.rsync}/bin/rsync -a --delete \
            --exclude='.env' \
            --exclude='storage' \
            --exclude='bootstrap/cache' \
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
  };
}
