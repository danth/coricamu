{ coricamuLib, pkgsLib, pkgs, config, websiteConfig, name, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

{
  imports = [ ./sitemap.nix ];

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

        Much of the head can be generated automatically based on other
        options. You should check if a more specific option is available
        before using this!

        Note: image sources and other links in your HTML are relative to the
        root of the website, whereas usually they would be relative to the
        current page. Therefore, it's recommended not to add a
        <literal>/</literal> at the beginning of relative links, so that the
        website can render correctly when it is previewed locally.
      '';
      example = ''
        <script type="text/javascript" src="https://example.com/externalscript.js" />
      '';
      type = lines;
    };

    body = mkOption {
      description = "Main content of the page.";
      example.markdown = ''
        # Contact Us

        You can reach us by contacting any of the following people:

        - <templates.user id="12345">Jane Doe</templates.user>
        - <templates.user id="67890">John Doe</templates.user>
      '';
      type = content websiteConfig.templates;
    };

    file = mkOption {
      description = "Compiled HTML file for this page.";
      internal = true;
      readOnly = true;
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

      <base href="${websiteConfig.baseUrl}">

      <meta charset="UTF-8">
      ${mapAttrsToString (name: content: ''
        <meta name="${name}" content="${content}">
      '') config.meta}

      <link rel="canonical" href="${websiteConfig.baseUrl}${config.path}">

      ${mapAttrsToString (name: style: ''
        <link rel="stylesheet" href="${style.path}">
      '') websiteConfig.styles}
    '';

    file = pkgs.writeTextFile {
      name = "${name}.html";

      text = ''
        <!DOCTYPE html>
        <html>
          <head>${config.head}</head>
          <body>
            ${
              optionalString
              (notNull websiteConfig.header)
              "<header>${websiteConfig.header.output}</header>"
            }
            <main>${config.body.output}</main>
            ${
              optionalString
              (notNull websiteConfig.footer)
              "<footer>${websiteConfig.footer.output}</footer>"
            }
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
