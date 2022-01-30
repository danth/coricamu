{ coricamuLib, pkgsLib, pkgs, config, websiteConfig, name, ... }:

with coricamuLib;
with pkgsLib;
with types;

{
  options = {
    path = mkOption {
      description = "Path of the page relative to the root URL.";
      type = strMatching ".*\\.html";
    };

    title = mkOption {
      description = "Title of the page.";
      type = str;
    };

    meta = mkOption {
      description = ''
        HTML metadata.

        Each key-value pair in this attribute set will be transformed into a
        corresponding HTML <literal>meta</literal> element with
        <literal>name</literal> set to the attribute name and
        <literal>content</literal> set to the attribute value.
      '';
      type = attrsOf str;
    };

    head = mkOption {
      description = ''
        HTML head of the page.

        May contain <literal>templates.«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be
        passed to the template as an attribute set, along with any HTML
        inside the tag as the <literal>contents</literal> attribute.

        Much of the head can be generated automatically based on other
        options. You should check if a more specific option is available
        before using this!
      '';
      example = ''
        <templates.metaAuthor name="John Doe" email="someone@example.com" />
      '';
      type = lines;
    };

    body = mkOption {
      description = ''
        HTML body of the page.

        May contain <literal>templates.«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be
        passed to the template as an attribute set, along with any HTML
        inside the tag as the <literal>contents</literal> attribute.
      '';
      example = ''
        <h1>Contact Us</h1>
        <p>You can reach us by contacting any of the following people:</p>
        <ul>
          <li><templates.user id="12345">Jane Doe</templates.user></li>
          <li><templates.user id="67890">John Doe</templates.user></li>
        </ul>
      '';
      type = lines;
    };

    file = mkOption {
      description = "Compiled HTML file for this page.";
      internal = true;
      type = package;
    };
  };

  config = {
    meta = {
      viewport = mkDefault "width=device-width, initial-scale=1";
      generator = mkDefault "Coricamu";  # We do a little advertising
    };

    head = ''
      <title>${config.title}</title>

      <meta charset="UTF-8">
      ${mapAttrsToString (name: content: ''
        <meta name="${name}" content="${content}">
      '') config.meta}

      ${mapAttrsToString (name: style: ''
        <link rel="stylesheet" href="${style.path}">
      '') websiteConfig.styles}
    '';

    file = pkgs.writeTextFile {
      name = "${name}.html";

      text = ''
        <!DOCTYPE html>
        <html>
          <head>
            ${fillTemplates {
              name = "${name}-head";
              html = config.head;
              inherit (websiteConfig) templates;
            }}
          </head>
          <body>
            ${fillTemplates {
              name = "${name}-body";
              html = config.body;
              inherit (websiteConfig) templates;
            }}
          </body>
        </html>
      '';

      # 3-in-1:
      # - Raises an error if the HTML is invalid
      # - Warns the user about accessibility problems
      # - Cleans up erratic indentation caused by templates
      checkPhase = ''
        ${pkgs.html-tidy}/bin/tidy \
          --accessibility-check 3 \
          --doctype html5 \
          --indent auto \
          --wrap 100 \
          --clean yes \
          --logical-emphasis yes \
          --coerce-endtags no \
          --quiet yes \
          -modify $target
      '';
    };
  };
}
