{ isToplevel }:
{ coricamuLib, pkgsLib, config, ... }:

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
    (if isToplevel
    then {
      default = [(import ./default)];
      defaultText = literalDocBook "Basic style sheet bundled with Coricamu.";
    }
    else {
      default = [];
    });

  config.files = pipe config.styles [
    (map (style: nameValuePair style.path style.output))
    listToAttrs
    (mkIf isToplevel)
  ];
}
