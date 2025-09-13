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
      pelicanPanelPackage = pkgs.callPackage ./lib/pelican-panel.nix { };
      wingsPackage = pkgs.callPackage ./lib/wings.nix { };
    in
    {
      packages.${system} = {
        default = pelicanPanelPackage;
        pelican-panel = pelicanPanelPackage;
        wings = wingsPackage;
      };

      nixosModules.pelican-panel =
        args:
        import ./modules/pelican-panel.nix (
          args
          // {
            pkgs = pkgs;
            pelicanPanelPkg = pelicanPanelPackage;
          }
        );

      nixosModules.wings =
        args:
        import ./modules/wings.nix (
          args
          // {
            pkgs = pkgs;
            wingsPackage = wingsPackage;
          }
        );
    };
}
