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

    header = mkOption {
      description = ''
        HTML header content, inserted before the body of every page.

        May contain <literal>templates-«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be passed
        to the template as an attribute set, along with any HTML inside the tag
        as the <literal>contents</literal> attribute.
      '';
      example = ''
        <h1>My Website</h1>
      '';
      type = nullOr lines;
      default = null;
    };

    footer = mkOption {
      description = ''
        HTML footer content, inserted after the body of every page.

        May contain <literal>templates-«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be passed
        to the template as an attribute set, along with any HTML inside the tag
        as the <literal>contents</literal> attribute.
      '';
      example = ''
        <a href="privacy.html">Privacy Policy</a>
      '';
      type = nullOr lines;
      default = null;
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
