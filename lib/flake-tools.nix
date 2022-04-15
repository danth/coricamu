{ self, nixpkgs, utils, ... }:

with utils.lib;

let
  # Generate the outputs for a particular system, in the format
  # packages.«outputName» = package
  generateSystemOutputs =
    { outputName, system, modules, specialArgs ? {} }:
    let
      siteArgs = { inherit modules specialArgs; };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: _prev: {
            coricamu = self.packages.${final.system};
          })
        ];
      };

      coricamuLib = import ./default.nix {
        inherit coricamuLib pkgs;
        pkgsLib = nixpkgs.lib;
      };
    in
    with coricamuLib;
    {
      packages."${outputName}" = buildSite siteArgs;

      apps."${outputName}-preview" = mkApp {
        name = "${outputName}-preview";
        drv = buildSitePreview siteArgs;
        exePath = "/bin/coricamu-preview";
      };
    };

  # Generate the outputs for all systems, in the format
  # packages.«system».«outputName» = package
  generateFlakeOutputs =
    args:
    eachDefaultSystem (system:
      generateSystemOutputs (args // { inherit system; })
    );

in {
  lib = {
    inherit generateSystemOutputs generateFlakeOutputs;
  };
}
