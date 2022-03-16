{ coricamuLib, pkgsLib, pkgs, ... }:

with pkgsLib;
with coricamuLib;

{
  fillTemplates =
    { name, html, templates, phase ? 1 }:
    let
      inherit (splitFilename name) baseName extension;
      nixName = "${baseName}-templates-phase${toString phase}.nix";

      nixFile = pkgs.runCommand nixName {
        inherit html;
        passAsFile = [ "html" ];

        # This is import-from-derivation, and is needed every time a user wants
        # to preview the site, so must be built quickly.
        preferLocalBuild = true;
        allowSubstitutes = false;
      } ''
        ${pkgs.coricamu.fill-templates}/bin/fill-templates <$htmlPath >$out
      '';

      wrappedTemplates = mapAttrs' (templateName: template: {
        # HTML tags are case-insensitive, so we convert the name to lowercase
        name = toLower templateName;
        value = template;
      }) templates;

      # If this string isn't present, template tags are definitely not used,
      # so the import-from-derivation can be skipped.
      mayContainTemplateTag = hasInfix "<templates-" html;

    in if mayContainTemplateTag
       then fillTemplates {
         inherit name templates;
         phase = phase + 1;
         html = (import nixFile) wrappedTemplates;
       }
       else html;
}
