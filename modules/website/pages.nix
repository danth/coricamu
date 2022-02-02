{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options = {
    pages = mkOption {
      description = "Attribute set of all pages.";
      type = attrsOf (page config);
    };

    header = mkOption {
      description = "Header inserted before the body of every page.";
      example.html = ''
        <h1>My Website</h1>
      '';
      type = nullOr (content config.templates);
      default = null;
    };

    footer = mkOption {
      description = "Footer inserted after the body of every page.";
      example.html = ''
        <a href="privacy.html">Privacy Policy</a>
      '';
      type = nullOr (content config.templates);
      default = null;
    };

    templates = mkOption {
      description = ''
        Attribute set of template functions.

        Note that because HTML tags are case-insensitive, template names will
        also be case-insensitive when used via template tags.
      '';
      type = attrsOf template;
    };
  };

  config.files = mapAttrs' (name: page:
    nameValuePair page.path page.file
  ) config.pages;
}
