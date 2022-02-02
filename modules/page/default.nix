{ coricamuLib, pkgsLib, pkgs, config, websiteConfig, name, ... }:

with coricamuLib;
with pkgsLib;
with types;

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

        May contain <literal>templates-«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be
        passed to the template as an attribute set, along with any HTML
        inside the tag as the <literal>contents</literal> attribute.

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
        <templates-metaAuthor name="John Doe" email="someone@example.com" />
      '';
      type = lines;
    };

    body = mkOption {
      description = ''
        HTML body of the page.

        May contain <literal>templates-«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be
        passed to the template as an attribute set, along with any HTML
        inside the tag as the <literal>contents</literal> attribute.

        Note: image sources and other links in your HTML are relative to the
        root of the website, whereas usually they would be relative to the
        current page. Therefore, it's recommended not to add a
        <literal>/</literal> at the beginning of relative links, so that the
        website can render correctly when it is previewed locally.
      '';
      example = ''
        <h1>Contact Us</h1>
        <p>You can reach us by contacting any of the following people:</p>
        <ul>
          <li><templates-user id="12345">Jane Doe</templates-user></li>
          <li><templates-user id="67890">John Doe</templates-user></li>
        </ul>
      '';
      type = lines;
    };

    markdownBody = mkOption {
      description = ''
        Markdown body of the page.

        May contain <literal>templates.«name»</literal> HTML tags in places
        where Markdown allows embedded HTML. This will call the corresponding
        template. HTML attributes (if present) will be passed to the template
        as an attribute set, along with any converted Markdown inside the tag
        as the <literal>contents</literal> attribute. Template tags are not
        guaranteed to work in all places when using Markdown - if you need more
        flexibility, consider writing the page directly in HTML instead.

        Note: image sources and other links in your Markdown are relative to
        the root of the website, whereas usually they would be relative to the
        current page. Therefore, it's recommended not to add a
        <literal>/</literal> at the beginning of relative links, so that the
        website can render correctly when it is previewed locally.

        Markdown will be inserted to <literal>body</literal> after it is
        converted. If you set <literal>body</literal> to something else, it
        will override the Markdown; therefore, it's recommended to only use
        either <literal>body</literal> or <literal>markdownBody</literal>, not
        both.
      '';
      example = ''
        # Contact Us

        You can reach us by contacting any of the following people:

        - <templates.user id="12345">Jane Doe</templates.user>
        - <templates.user id="67890">John Doe</templates.user>
      '';
      type = nullOr lines;
      default = null;
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

      <base href="${websiteConfig.baseUrl}">

      <meta charset="UTF-8">
      ${
        mapAttrsToString
        (name: content: "<meta name=\"${name}\" content=\"${content}\">")
        (websiteConfig.meta // config.meta)
      }

      <link rel="canonical" href="${websiteConfig.baseUrl}${config.path}">

      ${mapAttrsToString (name: style: ''
        <link rel="stylesheet" href="${style.path}">
      '') websiteConfig.styles}
    '';

    body = mkIf
      (!(isNull config.markdownBody))
      (convertMarkdown {
        name = "${name}-source";
        markdown = config.markdownBody;
      });

    file = pkgs.writeTextFile {
      name = "${name}.html";

      text = let
        makeTag =
          { name, tag, html }:
          ''
            <${tag}>
              ${fillTemplates {
                inherit name html;
                inherit (websiteConfig) templates;
              }}
            </${tag}>
          '';

        makeOptionalTag =
          { html, ... }@args:
          if isNull html then "" else makeTag args;

      in ''
        <!DOCTYPE html>
        <html>
          ${makeTag {
            name = "${name}-head";
            tag = "head";
            html = config.head;
          }}
          <body>
            ${makeOptionalTag {
              name = "header";
              tag = "header";
              html = websiteConfig.header;
            }}
            ${makeTag {
              name = "${name}-main";
              tag = "main";
              html = config.body;
            }}
            ${makeOptionalTag {
              name = "footer";
              tag = "footer";
              html = websiteConfig.footer;
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
