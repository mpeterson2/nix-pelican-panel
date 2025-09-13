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

  tokenWriterScript = pkgs.writeShellScript "wings-token-writer" ''
    #!/usr/bin/env bash
    set -euo pipefail
    TOKEN=$(${pkgs.coreutils}/bin/cat ${cfg.node.tokenPath})
    ${pkgs.yq-go}/bin/yq -i ".token = \"$TOKEN\"" "${configPath}"
  '';
in
{
  options.services.wings = {
    enable = lib.mkEnableOption "Enable wings.";

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
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ wingsPackage ];
    environment.etc."${configPathInEtc}".source = (pkgs.formats.yaml { }).generate "" (
      convertAttributes cfg.node
    );

    virtualisation.docker.enable = true;

    systemd.services.wings = {
      description = "Wings Daemon";
      after = [
        "network.target"
        "docker.service"
      ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${wingsPackage}/bin/wings";
        Restart = "always";
        RestartSec = "5s";
        SupplementaryGroups = [ "docker" ];
      };
    };

    systemd.services.wings-token-writer = {
      description = "Write token";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = tokenWriterScript;
      };
    };

    users.users.pelican = {
      isSystemUser = true;
      group = "pelican";
    };

    users.groups.pelican = { };
  };
}
