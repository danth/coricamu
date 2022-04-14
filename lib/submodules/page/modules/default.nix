{ coricamuLib, pkgsLib, config, websiteConfig, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

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
      type = content;
    };

    files = mkOption {
      description = "Attribute set containing files by path.";
      type = attrsOf (either package path);
      default = {};
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

      ${pipe (config.styles ++ websiteConfig.styles) [
        (catAttrs "path")
        lists.unique
        (concatMapStringsSep "\n" (path: ''
          <link rel="stylesheet" href="/${path}">
        ''))
      ]}
    '';

    files.${config.path} = absolutifyUrls {
      name = config.path;
      baseUrl = "${websiteConfig.baseUrl}${config.path}";
      html = fillTemplates {
        html = ''
          <!DOCTYPE html>
          <html lang="${websiteConfig.language}">
            <head>${config.head}</head>
            <body>
              ${
                optionalString
                (websiteConfig.header != null)
                "<header>${websiteConfig.header.output}</header>"
              }
              <main>${config.body.output}</main>
              ${
                optionalString
                (websiteConfig.footer != null)
                "<footer>${websiteConfig.footer.output}</footer>"
              }
            </body>
          </html>
        '';
        name = config.path;
        inherit (websiteConfig) templates;
      };
    };
  };
}
