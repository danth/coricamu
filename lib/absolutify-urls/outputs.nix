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
    packages.absolutify-urls = buildPackage {
      inherit src cargoArtifacts;
    };

    checks.absolutify-urls-clippy = cargoClippy {
      inherit src cargoArtifacts;
      cargoClippyExtraArgs = "-- --deny warnings";
    };
  }
)
