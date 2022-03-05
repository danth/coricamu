{ coricamuLib, pkgsLib, pkgs, config, websiteConfig, ... }:

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

      <meta charset="UTF-8">
      ${
        mapAttrsToString
        (name: content: "<meta name=\"${name}\" content=\"${content}\">")
        (websiteConfig.meta // config.meta)
      }

      <link rel="canonical" href="/${config.path}">

      ${concatMapStringsSep "\n" (style: ''
        <link rel="stylesheet" href="/${style.path}">
      '') websiteConfig.styles}
    '';

    file = pkgs.writeTextFile {
      name = config.path;

      text = ''
        <!DOCTYPE html>
        <html lang="${websiteConfig.language}">
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

      checkPhase = ''
        # Convert relative paths into absolute URLs
        ${absolutifyCommand {
          file = "$target";
          inherit (websiteConfig) baseUrl;
          inherit (config) path;
        }}

        ${pkgs.nodePackages.html-minifier}/bin/html-minifier \
          --collapse-boolean-attributes \
          --collapse-whitespace --conservative-collapse \
          --remove-comments \
          --remove-optional-tags \
          --remove-redundant-attributes \
          --remove-script-type-attributes \
          --remove-style-link-type-attributes \
          --sort-attributes \
          --sort-class-name \
          $target --output $target
      '';
    };
  };
}
