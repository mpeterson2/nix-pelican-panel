{
  lib,
  config,
  wingsPackage,
  pkgs,
  ...
}:
let
  cfg = config.services.wings;
in
{
  options.services.wings = {
    enable = lib.mkEnableOption "Enable wings.";

    user = lib.mkOption {
      description = "The user Wings should run as.";
      default = "wings";
      type = lib.types.string;
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
            description = "The Node's ID.";
            type = lib.types.str;
          };

          tokenId = lib.mkOption {
            description = "The Node's token id.";
            type = lib.types.str;
          };

          token = lib.mkOption {
            description = "The path to your token.";
            type = lib.types.path;
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
    environment.etc."/pelican/config.yml".source = (pkgs.formats.yaml { }).generate "" cfg.node;
  };
}
