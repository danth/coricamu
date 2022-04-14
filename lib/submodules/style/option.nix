{ insertDefault }:
{ coricamuLib, pkgsLib, config, ... }@args:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options.styles = mkOption {
    description = "Attribute set of CSS styles included in all pages.";
    type =
      # Backwards compatibility - this used to be an attribute set
      coercedTo attrs attrValues
      # Current type
      (listOf (style config));
  } //
    (if insertDefault
    then {
      default = [(import ./default)];
      defaultText = "Basic style sheet bundled with Coricamu.";
    }
    else {
      default = [];
    });

  config.files = listToAttrs (map (style:
    nameValuePair style.path style.output
  ) config.styles);
}
