{ pkgsLib, config, ... }@args:

with pkgsLib;
with types;

let
  image = submoduleWith {
    modules = [ ../image/default.nix ];
    specialArgs = {
      inherit (args) coricamuLib pkgsLib pkgs;
      websiteConfig = config;
    };
    shorthandOnlyDefinesConfig = true;
  };

in {
  options.images = mkOption {
    description = "List of images available to all pages.";
    type = listOf image;
    default = [];
  };

  config.files = listToAttrs (map (image:
    nameValuePair image.path image.outputFile
  ) config.images);
}
