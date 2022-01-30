{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, utils, self, ... }: {
    lib.buildSite =
      { system, modules, specialArgs ? {} }:
      let
        commonModules = [
          ./coricamu/files.nix
          ./coricamu/pages.nix
        ];

        commonArgs = {
          modulesPath = ./coricamu;
          inherit (nixpkgs) lib;
          pkgs = nixpkgs.legacyPackages.${system};
        };

        eval = nixpkgs.lib.evalModules {
          modules = commonModules ++ modules;
          specialArgs = commonArgs // specialArgs;
        };
      in eval.config.package;
  } //
  utils.lib.eachDefaultSystem (system: {
    packages.exampleWebsite = self.lib.buildSite {
      inherit system;
      modules = [ ./example/default.nix ];
    };
  });
}
