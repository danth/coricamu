{ pkgsLib, pkgs, config, ... }@args:

with pkgsLib;
with types;

let

  page = submoduleWith {
    modules = [ ../page/default.nix ];
    specialArgs = {
      inherit (args) coricamuLib pkgsLib pkgs;
      websiteConfig = config;
    };
    shorthandOnlyDefinesConfig = true;
  };

  template = functionTo lines;

in {
  options = {
    pages = mkOption {
      description = "Attribute set of all pages.";
      type = attrsOf page;
    };

    templates = mkOption {
      description = "Attribute set of template functions.";
      type = attrsOf template;
    };
  };

  config.files = mapAttrs' (name: page:
    nameValuePair page.path page.file
  ) config.pages;
}
