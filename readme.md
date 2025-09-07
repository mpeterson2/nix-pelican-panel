# Nix Pelican Panel

Run Pelican Panel on NixOS

## Setup

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

  services.pelican-panel.enable = true;
}
```

**Setup the env file**

Run `sudo -u pelican-panel pelican-panel-artisan p:environment:setup` (assuming pelican-panel is the user you are using to run the app)

You can now modify the env in `/svr/http/pelican-panel/.env`