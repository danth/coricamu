{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options = {
    pages = mkOption {
      description = "List of all posts.";
      type =
        # Backwards compatibility - this used to be an attribute set
        coercedTo attrs attrValues
        # Current type
        (listOf (page config));
      default = [];
    };

    meta = mkOption {
      description = ''
        HTML metadata shared by all pages.

        Each key-value pair in this attribute set will be transformed into a
        corresponding HTML <literal>meta</literal> element with
        <literal>name</literal> set to the attribute name and
        <literal>content</literal> set to the attribute value.

        Note: there is also an option to set metadata for a particular page.
      '';
      type = attrsOf str;
      default = {};
    };

    header = mkOption {
      description = "Header inserted before the body of every page.";
      example.html = ''
        <h1>My Website</h1>
      '';
      type = nullOr (content config.templates);
      defaultText = ''
        Heading containing <literal>siteTitle</literal>, with a link
        to <literal>/index.html</literal>.
      '';
      default.html = ''
        <h1><a href="/index.html">${config.siteTitle}</a></h1>
      '';
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
      default = {};
    };
  };

  config.files =
    listToAttrs (map (page: nameValuePair page.path page.file) config.pages);
}
