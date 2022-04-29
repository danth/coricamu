{ coricamuLib, pkgsLib, pkgs, ... }:

with pkgsLib;
with coricamuLib;

{
  fillTemplates =
    { name, body, templates, phase ? 1, usedTemplates ? [] }:
    let
      inherit (splitFilename name) baseName;
      nixName = "${baseName}-templates-phase${toString phase}.nix";

      nixFile = pkgs.runCommand nixName {
        inherit body;
        passAsFile = [ "body" ];

        # This is import-from-derivation, and is needed every time a user wants
        # to preview the site, so must be built quickly.
        preferLocalBuild = true;
        allowSubstitutes = false;
      } ''
        ${pkgs.coricamu.fill-templates}/bin/fill-templates <$bodyPath >$out
      '';

      wrappedTemplates = mapAttrs' (templateName: template: {
        # HTML tags are case-insensitive, so we convert the name to lowercase
        name = toLower templateName;
        value = template;
      }) templates;

      # If this string isn't present, template tags are definitely not used,
      # so the import-from-derivation can be skipped.
      mayContainTemplateTag = hasInfix "<templates-" body;

    in if mayContainTemplateTag
       then let
         output = (import nixFile) wrappedTemplates;
       in fillTemplates {
         inherit name templates;
         inherit (output) body;
         phase = phase + 1;
         usedTemplates = usedTemplates ++ output.usedTemplates;
       }
       else {
         inherit usedTemplates body;
       };
}
