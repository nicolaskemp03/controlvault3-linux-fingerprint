{
  description = "ControlVault 3 (BCM58200) libfprint TOD driver — open-source, keyless";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    packages.${system} = {
      libfprint-2-tod1-cvfp = pkgs.callPackage ./default.nix { };
      default = self.packages.${system}.libfprint-2-tod1-cvfp;
    };

    overlays.default = final: prev: {
      libfprint-2-tod1-cvfp = final.callPackage ./default.nix { };
    };
  };
}
