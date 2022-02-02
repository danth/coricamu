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
    type = attrsOf style;
    default = {};
  };

  config.files = mapAttrs' (name: style:
    nameValuePair style.path style.file
  ) config.styles;
}
