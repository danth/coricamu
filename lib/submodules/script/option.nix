{ isToplevel }:
{ coricamuLib, pkgsLib, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options.scripts = mkOption {
    description = "List of JavaScript files included in all pages.";
    type = listOf (script config);
    default = [];
  };

  config.files = pipe config.scripts [
    (map (script: nameValuePair script.path script.output))
    listToAttrs
    (mkIf isToplevel)
  ];
}
