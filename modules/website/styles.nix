{ pkgsLib, config, ... }@args:

with pkgsLib;
with types;

let
  style = submoduleWith {
    modules = [ ../style/default.nix ];
    specialArgs = {
      inherit (args) coricamuLib pkgsLib pkgs;
      websiteConfig = config;
    };
    shorthandOnlyDefinesConfig = true;
  };

in {
  options.styles = mkOption {
    description = "Attribute set of CSS styles included in all pages.";
    type =
      # Backwards compatibility - this used to be an attribute set
      coercedTo attrs attrValues
      # Current type
      (listOf style);
    default = [{
      path = "coricamu.css";
      scss = builtins.readFile ../../defaults/coricamu.scss;
    }];
    defaultText = "Basic style sheet bundled with Coricamu.";
  };

  config.files = listToAttrs (map (style:
    nameValuePair style.path style.output
  ) config.styles);
}
