{
  lib,
  config,
  wingsPackage,
  pkgs,
  ...
}:
let
  cfg = config.services.wings;
  toSnakeCase = import ../utils/to-snake-case.nix { inherit lib; };
  convertAttributes = import ../utils/convert-attributes.nix {
    inherit lib;
    converter = toSnakeCase;
  };

  configPathInEtc = "/pelican/config.yml";
  configPath = "/etc" + configPathInEtc;

  configWithoutToken = convertAttributes (removeAttrs cfg.node [ "tokenPath" ]);

  baseConfigFile = (pkgs.formats.yaml { }).generate "wings-config-base.yml" configWithoutToken;

  setupConfigScript = pkgs.writeShellScript "setup-wings-config" ''
    set -euo pipefail

    if [ ! -f "${cfg.node.tokenPath}" ]; then
      echo "Error: Token file ${cfg.node.tokenPath} not found!"
      exit 1
    fi

    TOKEN=$(${pkgs.coreutils}/bin/cat "${cfg.node.tokenPath}")

    ${pkgs.coreutils}/bin/mkdir -p /etc/pelican

    ${pkgs.coreutils}/bin/cp "${baseConfigFile}" "${configPath}.tmp"
    echo "token: $TOKEN" >> "${configPath}.tmp"
    ${pkgs.coreutils}/bin/mv "${configPath}.tmp" "${configPath}"

    ${pkgs.coreutils}/bin/chown pelican:pelican "${configPath}"
    ${pkgs.coreutils}/bin/chmod 640 "${configPath}"
  '';
in
{
  options.services.wings = {
    enable = lib.mkEnableOption "Enable wings.";

    openFirewall = lib.mkOption {
      description = "Whether to open the Wings port in the firewall.";
      default = true;
      type = lib.types.bool;
    };

    node = lib.mkOption {
      description = "Define your Wings nodes. Many of these values will come when creating your node from the panel.";
      default = { };
      type = lib.types.submodule {
        options = {
          debug = lib.mkOption {
            description = "Enable debug mode.";
            default = false;
            type = lib.types.bool;
          };

          uuid = lib.mkOption {
            description = "The node's ID.";
            type = lib.types.str;
          };

          tokenId = lib.mkOption {
            description = "The node's token id.";
            type = lib.types.str;
          };

          tokenPath = lib.mkOption {
            description = "The filepath to the node's token.";
            type = lib.types.str;
          };

          api = lib.mkOption {
            description = "The node's api config.";
            default = { };
            type = lib.types.submodule {
              options = {
                host = lib.mkOption {
                  description = "The host your node will listen on.";
                  default = "0.0.0.0";
                  type = lib.types.str;
                };

                port = lib.mkOption {
                  description = "The port your node will listen on.";
                  default = 8080;
                  type = lib.types.int;
                };

                ssl = lib.mkOption {
                  description = "SSL Options.";
                  default = { };
                  type = lib.types.submodule {
                    options = {
                      enabled = lib.mkEnableOption "Enable SSL.";

                      cert = lib.mkOption {
                        description = "The path to your certificate file.";
                        default = null;
                        type = lib.types.nullOr lib.types.path;
                      };
                      key = lib.mkOption {
                        description = "The path to your private key file.";
                        default = null;
                        type = lib.types.nullOr lib.types.path;
                      };
                    };
                  };
                };

                uploadLimit = lib.mkOption {
                  description = "Max filesize that can be uploaded through the browser.";
                  default = 256;
                  type = lib.types.int;
                };
              };
            };
          };

          system = lib.mkOption {
            description = "The node's system settings.";
            default = { };
            type = lib.types.submodule {
              options = {
                data = lib.mkOption {
                  description = "Path to store the node's data.";
                  default = "/var/lib/pelican/volumes";
                  type = lib.types.path;
                };

                sftp = lib.mkOption {
                  description = "The node's SFTP options.";
                  default = { };
                  type = lib.types.submodule {
                    options = {
                      enable = lib.mkEnableOption "Enable SFTP.";

                      bindPort = lib.mkOption {
                        description = "The port SFTP will bind to.";
                        default = 2022;
                        type = lib.types.int;
                      };
                    };
                  };
                };
              };
            };
          };

          allowedMounts = lib.mkOption {
            description = "Allowed mounts for the node.";
            default = [ ];
            type = lib.types.listOf lib.types.str;
          };

          remote = lib.mkOption {
            description = "The remote of the node.";
            type = lib.types.str;
          };

          allowedOrigins = lib.mkOption {
            description = "Allowed CORS origins for the node.";
            default = [ ];
            type = lib.types.listOf lib.types.str;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ wingsPackage ];

    virtualisation.docker.enable = true;

    systemd.tmpfiles.rules = [
      "d /etc/pelican 0755 pelican pelican -"
    ];

    systemd.services.wings-config-setup = {
      description = "Setup Wings configuration with token";
      wantedBy = [ "multi-user.target" ];
      before = [ "wings.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = setupConfigScript;
        RemainAfterExit = true;
      };

      restartTriggers = [ cfg.node.tokenPath ];
    };

    systemd.services.wings = {
      description = "Wings Daemon";
      after = [
        "network.target"
        "docker.service"
        "wings-config-setup.service"
      ];
      requires = [
        "docker.service"
        "wings-config-setup.service"
      ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p /var/log/pelican
        chown pelican:pelican /var/log/pelican
      '';

      serviceConfig = {
        ExecStart = "${wingsPackage}/bin/wings";
        User = "pelican";
        Group = "pelican";
        Restart = "always";
        RestartSec = "5s";
        SupplementaryGroups = [ "docker" ];
        WorkingDirectory = "/var/lib/pelican";
        StateDirectory = "pelican";
        LogsDirectory = "pelican";
        AmbientCapabilities = [
          "CAP_CHOWN"
          "CAP_DAC_OVERRIDE"
        ];
      };
    };

    users.users.pelican = {
      isSystemUser = true;
      group = "pelican";
      extraGroups = [ "docker" ];
    };

    users.groups.pelican = { };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.node.api.port ];
  };
}
