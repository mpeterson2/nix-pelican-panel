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
        import ./modules/pelican-panel.nix (
          args
          // {
            pkgs = pkgs;
            pelicanPanelPkg = package;
          }
        );

      nixosModules.wings =
        args:
        import ./modules/wings.nix (
          args
          // {
            pkgs = pkgs;
          }
        );
    };
}
