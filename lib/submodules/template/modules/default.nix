{ coricamuLib, pkgsLib, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options = {
    function = mkOption {
      description = "Function which produces a string of HTML.";
      type = functionTo lines;
    };

    head = mkOption {
      description = ''
        HTML head of the page.

        Much of the head can be generated automatically based on other
        options. You should check if a more specific option is available
        before using this!
      '';
      example = ''
        <script type="text/javascript" src="https://example.com/externalscript.js" />
      '';
      type = lines;
      default = "";
    };

    meta = mkOption {
      description = ''
        HTML metadata for this page.

        Each key-value pair in this attribute set will be transformed into a
        corresponding HTML <literal>meta</literal> element with
        <literal>name</literal> set to the attribute name and
        <literal>content</literal> set to the attribute value.

        Note: there is also an option to set metadata shared between all pages.
      '';
      type = attrsOf str;
      default = {};
    };

    files = mkOption {
      description = "Attribute set containing files by path.";
      type = attrsOf file;
      default = {};
    };
  };
}
