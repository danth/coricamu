{ allowNull ? false }:
{ pkgsLib, config, name, ... }:

with pkgsLib;
with pkgsLib.types;

{
  imports = [ ./docbook.nix ./html.nix ./markdown.nix ];

  options = {
    outputs = mkOption {
      description = ''
        List of compiled HTML outputs.

        When this submodule is used correctly, there should be exactly
        one value here.
      '';
      internal = true;
      type = listOf lines;
    };

    output = mkOption {
      description = "Compiled HTML.";
      internal = true;
      readOnly = true;
      type = if allowNull then nullOr lines else lines;
    };
  };

  config.output =
    if length config.outputs == 0
    then
      if allowNull
      then null
      else throw "No content is defined for ${name}"
    else
      if length config.outputs > 1
      then throw "Multiple content types used at once for ${name}"
      else elemAt config.outputs 0;
}
