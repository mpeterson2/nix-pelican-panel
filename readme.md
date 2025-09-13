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

** Run migrations**

Run `sudo -u pelican-panel pelican-panel-artisan migrate`.
