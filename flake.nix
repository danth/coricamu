{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, utils, ... }:
    with utils.lib;
    let
      # Generate the outputs for a particular system, in the format
      # packages.«outputName» = package
      generateSystemOutputs =
        { outputName, system, modules, specialArgs ? {} }:
        let
          siteArgs = { inherit modules specialArgs; };

          coricamuLib = import ./lib/default.nix {
            inherit coricamuLib;
            pkgsLib = nixpkgs.lib;
            pkgs = nixpkgs.legacyPackages.${system};
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
      lib = { inherit generateSystemOutputs generateFlakeOutputs; };
    } //
    (generateFlakeOutputs {
      outputName = "example";
      modules = [ ./example/default.nix ];
    });
}
