{ coricamuLib, pkgsLib, pkgs, config, websiteConfig, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

let
  filledTemplates = fillTemplates {
    inherit (websiteConfig) templates;
    body = ''
      ${
        optionalString
        (websiteConfig.header.output != null)
        "<header>${websiteConfig.header.output}</header>"
      }
      <main>${config.body.output}</main>
      ${
        optionalString
        (websiteConfig.footer.output != null)
        "<footer>${websiteConfig.footer.output}</footer>"
      }
    '';
  };

  inherit (filledTemplates) usedTemplates;

in {
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
      default = "";
    };

    body = mkOption {
      description = "Main content of the page.";
      example.markdown = ''
        # Contact Us

        You can reach us by contacting any of the following people:

        - <templates.user id="12345">Jane Doe</templates.user>
        - <templates.user id="67890">John Doe</templates.user>
      '';
      type = content {};
    };

    files = mkOption {
      description = "Attribute set containing files by path.";
      type = attrsOf file;
      default = {};
    };
  };

  config = {
    meta = mkMerge ([{
      viewport = mkDefault "width=device-width, initial-scale=1";
      generator = mkDefault "Coricamu";  # We do a little advertising
    }] ++ catAttrs "meta" usedTemplates);

    head = mkMerge ([''
      <title>${config.title}</title>

      <base href="/${
        # If a website is served over both HTTP and a decentralised protocol
        # such as IPFS, users who have IPFS installed will load the website
        # from localhost rather than its original domain.
        #
        # If the HTTP domain was specified in the base URL, resources for the
        # page would always be loaded over HTTP rather than IPFS, nullifying
        # any benefits of providing the IPFS mirror. Furthermore, requests to
        # the HTTP server from a different domain are often blocked by CORS,
        # which breaks the page.
        #
        # To solve this, we give a directory path as the base without including
        # the domain name. The leading slash (above!) makes sure that the base
        # is not itself interpreted as relative to the current page.

        elemAt (builtins.match "[a-z]+://[^/]+/(.*)" websiteConfig.baseUrl) 0
      }" />

      <meta charset="UTF-8">
      ${
        mapAttrsToString
        (name: content: "<meta name=\"${name}\" content=\"${content}\">")
        (websiteConfig.meta // config.meta)
      }

      <link rel="canonical" href="${config.path}">

      ${pipe (config.styles ++ websiteConfig.styles) [
        (catAttrs "path")
        lists.unique
        (concatMapStringsSep "\n" (path: ''
          <link rel="stylesheet" href="${path}">
        ''))
      ]}

      ${pipe (config.scripts ++ websiteConfig.scripts) [
        lists.unique
        (concatMapStringsSep "\n" (script: ''
          <script
            src="${script.path}"
            ${optionalString script.defer "defer"}
          ></script>
        ''))
      ]}

      ${websiteConfig.head}
    ''] ++ catAttrs "head" usedTemplates);

    files = mkMerge ([{
      ${config.path} = pkgs.writeText config.path ''
        <!DOCTYPE html>
        <html lang="${websiteConfig.language}">
          <head>${config.head}</head>
          ${filledTemplates.body}
        </html>
      '';
    }] ++ catAttrs "files" usedTemplates);

    scripts = mkMerge (map
      (map (x: removeAttrs x [ "output" ]))
      (catAttrs "scripts" usedTemplates)
    );
    styles = mkMerge (map
      (map (x: removeAttrs x [ "output" ]))
      (catAttrs "styles" usedTemplates)
    );
    images = mkMerge (map
      (map (x: removeAttrs x [ "output" ]))
      (catAttrs "images" usedTemplates)
    );
  };
}
