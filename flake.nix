{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, utils, ... }:
    with utils.lib;
    let generateFlakeOutputs =
      outputName: args:
      eachDefaultSystem (
        system:
        let
          coricamuLib = import ./lib/default.nix {
            inherit coricamuLib;
            pkgsLib = nixpkgs.lib;
            pkgs = nixpkgs.legacyPackages.${system};
          };
        in
        with coricamuLib;
        {
          packages."${outputName}" = buildSite args;

          apps."${outputName}-preview" = mkApp {
            name = "${outputName}-preview";
            drv = buildSitePreview args;
            exePath = "/bin/coricamu-preview";
          };
        }
      );
    in {
      lib = { inherit generateFlakeOutputs; };
    } //
    (generateFlakeOutputs "example" {
      modules = [ ./example/default.nix ];
    });
}
