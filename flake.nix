{
  description = "Pelican Panel";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
  };

  outputs =
    { ... }:
    {
      nixosModules.pelican-panel = import ./module.nix;
    };
}
