{ utils, crane, ... }:

utils.lib.eachDefaultSystem (
  system:

  with crane.lib.${system};

  let
    src = ./.;

    cargoArtifacts = buildDepsOnly {
      inherit src;
    };

  in {
    packages.fill-templates = buildPackage {
      inherit src cargoArtifacts;
    };

    checks.fill-templates-clippy = cargoClippy {
      inherit src cargoArtifacts;
      cargoClippyExtraArgs = "-- --deny warnings";
    };
  }
)
