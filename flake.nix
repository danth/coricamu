{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system: rec {
      lib = import ./lib/default.nix {
        coricamuLib = lib;
        pkgsLib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.${system};
      };

      packages.exampleWebsite = lib.buildSite {
        modules = [ ./example/default.nix ];
      };
    });
}
