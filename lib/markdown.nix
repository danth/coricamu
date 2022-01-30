{ pkgs, ... }:

{
  convertMarkdown =
    { name, markdown }:
    let htmlFile = pkgs.runCommand "${name}.html" {
      inherit markdown;
      passAsFile = [ "markdown" ];

      # This is import-from-derivation, and is needed every time a user wants
      # to preview the site, so must be built quickly.
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      ${pkgs.multimarkdown}/bin/multimarkdown \
        --snippet --notransclude \
        --to=html --output=$out $markdownPath
    '';
    in builtins.readFile htmlFile;
}
