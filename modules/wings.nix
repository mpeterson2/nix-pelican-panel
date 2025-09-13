{
  lib,
  config,
  ...
}:
let
  cfg = config.services.pelican-panel;
in
{
  options.services.wings = {
    enable = lib.mkEnableOption "Enable wings.";
    nodes = lib.mkOption {
      type = lib.types.listOf lib.types.submodule {
        options = {
          debug = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable debug mode.";
          };
          uuid = lib.mkOption {
            type = lib.types.str;
            description = "The Node's ID.";
          };
          tokenId = lib.mkOption {
            type = lib.types.str;
            description = "The Node's token id.";
          };
          token = lib.mkOption {
            type = lib.types.path;
            description = "The path to your token.";
          };
          api = lib.mkOption {
            type = lib.types.submodule {
              options = {
                host = {
                  type = lib.types.str;
                  default = "0.0.0.0";
                  description = "The host your node will listen on.";
                };
                port = {
                  type = lib.types.int;
                  default = 8080;
                  description = "The port your node will listen on.";
                };
                ssl = {
                  enable = lib.mkEnableOption "Enable SSL.";
                  cert = lib.mkOption {
                    type = lib.types.nullOr lib.types.path;
                    default = null;
                    description = "The path to your certificate file.";
                  };
                  key = lib.mkOption {
                    type = lib.types.nullOr lib.types.path;
                    default = null;
                    description = "The path to your private key file.";
                  };
                };
                uploadLimit = lib.mkOption {
                  type = lib.types.int;
                  default = 256;
                  description = "Max filesize that can be uploaded through the browser.";
                };
              };
            };
            description = "The node's api config.";
            default = { };
          };
          system = lib.mkOption {
            type = lib.submodule {
              options = {
                data = lib.mkOption {
                  type = lib.types.path;
                  default = "/var/lib/pelican/volumes";
                  description = "Path to store the node's data.";
                };
                sftp = lib.mkOption {
                  type = lib.submodule {
                    options = {
                      enable = lib.mkEnableOption "Enable SFTP.";
                      bindPort = {
                        type = lib.types.int;
                        default = 2022;
                        description = "The port SFTP will bind to.";
                      };
                    };
                  };
                  default = { };
                  description = "The node's SFTP options";
                };
              };
            };
            default = { };
            description = "The node's system settings";
          };
          allowedMounts = lib.mkOption {
            type = lib.listOf lib.types.str;
            default = [ ];
            description = "Allowed mounts for the node.";
          };
          remote = lib.mkOption {
            type = lib.types.str;
            description = "The remote of the node.";
          };
        };
        default = { };
        description = "Define your Wings nodes. Many of these values will come when creating your node from the panel.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
  };
}
