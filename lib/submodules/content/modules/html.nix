{ coricamuLib, pkgsLib, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options = {
    html = mkOption {
      description = ''
        HTML content.

        May contain <literal>templates-«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be
        passed to the template as an attribute set, along with any HTML
        inside the tag as the <literal>contents</literal> attribute.
      '';
      example = ''
        <h1>Contact Us</h1>
        <p>You can reach us by contacting any of the following people:</p>
        <ul>
          <li><templates-user id="12345">Jane Doe</templates-user></li>
          <li><templates-user id="67890">John Doe</templates-user></li>
        </ul>
      '';
      type = nullOr lines;
      default = null;
    };

    htmlFile = mkOption {
      description = ''
        A file containing HTML.

        May contain <literal>templates-«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be
        passed to the template as an attribute set, along with any HTML
        inside the tag as the <literal>contents</literal> attribute.
      '';
      example = "./example.html";
      type = nullOr file;
      default = null;
    };
  };

  config.outputs =
    with config;
    optional (html != null) html
    ++ optional (htmlFile != null) (builtins.readFile htmlFile);
}
