{ lib, pkgs, config, ... }:

with lib;
with types;

let
  page = submodule [{
    options = {
      path = mkOption {
        description = "Path of the page relative to the root URL.";
        type = strMatching ".*\\.html";
      };

      title = mkOption {
        description = "Title of the page.";
        type = str;
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
    };
  }];

  template = functionTo lines;

  makePageFile = name: page:
    let
      nixBody = pkgs.runCommand "${name}.html.nix" {
        python = pkgs.python3.withPackages (ps: [ ps.beautifulsoup4 ]);
        inherit (page) body;
        passAsFile = [ "body" ];
      } ''
        $python/bin/python ${./nixify_templates.py} $bodyPath $out
      '';

      htmlBody = (import nixBody) config.templates;

      htmlFile = pkgs.writeTextFile {
        name = "${name}.html";

        text = ''
          <!DOCTYPE html>
          <html>
            <head>
              <title>${page.title}</title>
              <meta charset="UTF-8">
              <meta name="generator" content="Coricamu">
              <meta name="viewport" content="width=device-width,initial-scale=1">
            </head>
            <body>
              ${htmlBody}
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

    in nameValuePair page.path htmlFile;

in {
  options = {
    pages = mkOption {
      description = "Attribute set of all pages.";
      type = attrsOf page;
    };

    templates = mkOption {
      description = "Attribute set of template functions.";
      type = attrsOf template;
    };
  };

  config.files = mapAttrs' makePageFile config.pages;
}
