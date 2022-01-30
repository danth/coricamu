{ coricamuLib, pkgsLib, pkgs, ... }:

with pkgsLib;

{
  fillTemplates =
    { name, html, templates }:
    let
      python = pkgs.python3.withPackages (ps: [ ps.beautifulsoup4 ]);

      nixFile = pkgs.runCommand "${name}.html.nix" {
        inherit html;
        passAsFile = [ "html" ];

        # This is import-from-derivation, and is needed every time a user wants
        # to preview the site, so must be built quickly.
        preferLocalBuild = true;
        allowSubstitutes = false;
      } ''
        ${python}/bin/python ${./template_tags.py} $htmlPath $out
      '';

      # Apply fillTemplates to the HTML returned by each used template,
      # in case it contains template tags itself
      wrappedTemplates = mapAttrs (
        templateName: template:
        # Wrap the template function
        templateArgs:
        coricamuLib.fillTemplates {
          name = templateName;
          html = template templateArgs;
          inherit templates;
        }
      ) templates;

      # If this string isn't present, template tags are definitely not used,
      # so the import-from-derivation can be skipped.
      mayContainTemplateTag = hasInfix "<templates-" html;

    in if mayContainTemplateTag
       then (import nixFile) wrappedTemplates
       else html;
}
