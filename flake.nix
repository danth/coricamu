{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:

    let
      # Coricamu's flake outputs are coded across multiple Nix files.
      # The following two functions help to collect the outputs into
      # one value so that they can be returned here.

      mergeOutputs = 
        outputs:
        with nixpkgs.lib;
        fold recursiveUpdate {} outputs;

      callOutputs = file: import file inputs;

      # libOutputs contains the value of `«Coricamu's flake».lib`,
      # which is used to build the docs website.

      libOutputs = callOutputs ./lib/flake-tools.nix;

      docsOutputs = libOutputs.lib.generateFlakeOutputs {
        outputName = "docs";
        modules = [ ./docs/default.nix ];
      };

    in mergeOutputs [
      libOutputs
      docsOutputs
      {
        hydraJobs = {
          inherit (self.packages.x86_64-linux) docs;
        };
      }
    ];
}
