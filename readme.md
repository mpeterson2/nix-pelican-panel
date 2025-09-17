# Nix Pelican Panel

Run Pelican Panel on NixOS

> [!WARNING]
> This readme assumes you did not modify default settings. Some commands may need to change if you do.

## Usage

**Update your flake**

```nix
inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    pelican-panel = {
      url = "<TODO>";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
outputs =
  {
    nixpkgs,
    ...
  }@inputs:
  {
    nixosConfigurations = {
      <hostname> = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ... ];
      };
    };
  };
```

**Update your configuration.nix**

```nix
{ inputs, config, ... }:
{
  imports = [
    inputs.pelican-panel.nixosModules.pelican-panel
  ];

  services.pelican-panel = {
    enable = true;
    nginx.enable = true;
  };
}
```

**Setup the env file**

Run `sudo -u pelican-panel pelican-panel-artisan p:environment:setup`.

You can now modify the env in `/svr/http/pelican-panel/.env`.

**Run migrations**

Run `sudo -u pelican-panel pelican-panel-artisan migrate`.

**Install your panel**

Navigate to your pelican panel's `/installer` route and follow the instructions

**Setup Wings**

On the panel, create a wing, note the config and translate it to nix config:

```nix
{ inputs, config, ... }:
{
  imports = [
    inputs.pelican-panel.nixosModules.wings
  ];

  services.wings = {
    enable = true;
    node = {
      uuid = "<node-uuid>";
      tokenId = "<node-token>";
      # Recommended to use sops or another form of encrypting this value
      tokenPath = config.sops.secrets.wings-token.path;
      remote = "<node-remote>";
    };
  };
}
```

Note: This package provides the rest of the config as defaults, so no need to edit if you want to keep those.
