{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, self, ... }: {
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
  };
}
