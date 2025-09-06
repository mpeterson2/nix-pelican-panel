{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.pelican-panel;
in
{
  options.services.pelican-panel = {
    enable = lib.mkEnableOption "Pelican Panel service";

    greeting = lib.mkOption {
      type = lib.types.str;
      default = "World";
      description = "What Pelican Panel should say hello to.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.callPackage ./lib.nix { greeting = cfg.greeting; })
    ];
  };
}
