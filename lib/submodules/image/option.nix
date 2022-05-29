{ isToplevel }:
{ coricamuLib, pkgsLib, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options.images = mkOption {
    description = "List of images available to all pages.";
    type = listOf (image config);
    default = [];
  };

  config.files = pipe config.images [
    (map (image: nameValuePair image.path image.outputFile))
    listToAttrs
    (mkIf isToplevel)
  ];
}
