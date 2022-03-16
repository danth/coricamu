{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
  };

  outputs =
    { nixpkgs, utils, crane, ... }:
    with utils.lib;
    let
      makeRustPackage =
        { system, src }:
        with crane.lib.${system};
        let
          cargoArtifacts = buildDepsOnly {
            inherit src;
          };
        in {
          package = buildPackage {
            inherit src cargoArtifacts;
          };
          check = cargoClippy {
            inherit src cargoArtifacts;
            cargoClippyExtraArgs = "-- --deny warnings";
          };
        };

      makeOutputs =
        system:
        let
          fill-templates = makeRustPackage {
            inherit system;
            src = ./fill-templates;
          };
        in {
          packages = {
            fill-templates = fill-templates.package;
          };
          checks = {
            fill-templates = fill-templates.check;
          };
        };

      # Generate the outputs for a particular system, in the format
      # packages.«outputName» = package
      generateSystemOutputs =
        { outputName, system, modules, specialArgs ? {} }:
        let
          siteArgs = { inherit modules specialArgs; };

          coricamuLib = import ./lib/default.nix {
            inherit coricamuLib;
            pkgsLib = nixpkgs.lib;
            pkgs = import nixpkgs {
              inherit system;
              overlays = [(self: super: {
                coricamu = (makeOutputs self.system).packages;
              })];
            };
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
    (eachDefaultSystem makeOutputs) //
    (generateFlakeOutputs {
      outputName = "example";
      modules = [ ./example/default.nix ];
    });
}
