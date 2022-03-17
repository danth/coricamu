{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    utils.url = "github:numtide/flake-utils";

    # We could use `rustPlatform` from Nixpkgs to build the Rust helper
    # programs, but Crane splits the build into multiple derivations which may
    # be cached during development. It also provides the Clippy linter which is
    # used in the checks output.
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:

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
      # which is used to build the example website.

      libOutputs = mergeOutputs (map callOutputs [
        ./lib/flake-tools.nix
        ./lib/absolutify-urls/outputs.nix
        ./lib/fill-templates/outputs.nix
      ]);

      exampleOutputs = libOutputs.lib.generateFlakeOutputs {
        outputName = "example";
        modules = [ ./example/default.nix ];
      };

    in mergeOutputs [ libOutputs exampleOutputs ];
}
