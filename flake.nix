{
  description = "Pelican Panel";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
  };
  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      package = pkgs.callPackage ./lib/pelican-panel.nix { };
    in
    {
      packages.${system} = {
        default = package;
        pelican-panel = package;
      };

      nixosModules.pelican-panel =
        args:
        import ./module.nix (
          args
          // {
            pkgs = pkgs;
            pelicanPanelPkg = package;
          }
        );
    };
}
