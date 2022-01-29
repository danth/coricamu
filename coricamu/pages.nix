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

    config = {
      meta = {
        viewport = mkDefault "width=device-width, initial-scale=1";
        generator = mkDefault "Coricamu";  # We do a little advertising
      };
    };
  }];

  template = functionTo lines;

  fillTemplates =
    { name, body }:
    let
      python = pkgs.python3.withPackages (ps: [ ps.beautifulsoup4 ]);

      nixFile = pkgs.runCommand "${name}.html.nix" {
        inherit body;
        passAsFile = [ "body" ];

        # This is import-from-derivation, and is needed every time a user wants
        # to preview the site, so must be built quickly.
        preferLocalBuild = true;
        allowSubstitutes = false;
      } ''
        ${python}/bin/python ${./nixify_templates.py} $bodyPath $out
      '';

      # Apply fillTemplates to the HTML returned by each used template,
      # in case it contains template tags itself
      templates = mapAttrs (
        templateName: template:
        # Wrap the template function
        templateArgs:
        fillTemplates {
          name = templateName;
          body = template templateArgs;
        }
      ) config.templates;

      # If this string isn't present, template tags are definitely not used,
      # so the import-from-derivation can be skipped.
      mayContainTemplateTag = hasInfix "<templates." body;

    in if mayContainTemplateTag
       then (import nixFile) templates
       else body;

  makePageFile = name: page: pkgs.writeTextFile {
      name = "${name}.html";

      text = ''
        <!DOCTYPE html>
        <html>
          <head>
            <title>${page.title}</title>
            <meta charset="UTF-8">
            ${concatStringsSep "\n" (mapAttrsToList (name: content: ''
              <meta name="${name}" content="${content}">
            '') page.meta)}
          </head>
          <body>
            ${fillTemplates {
              inherit name;
              inherit (page) body;
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

  config.files = mapAttrs' (name: page:
    nameValuePair page.path (makePageFile name page)
  ) config.pages;
}
