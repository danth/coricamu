{ pkgs, ... }:

{
  convertDocbook =
    { name, docbook }:
    let htmlFile = pkgs.runCommand "${name}.html" {
      inherit docbook;
      passAsFile = [ "docbook" ];

      # This is import-from-derivation, and is needed every time a user wants
      # to preview the site, so must be built quickly.
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      ${pkgs.pandoc}/bin/pandoc -f docbook -t html <$docbookPath >$out
    '';
    in builtins.readFile htmlFile;

  convertDocbookFile =
    { name, file }:
    let htmlFile = pkgs.runCommand "${name}.html" {
      # This is import-from-derivation, and is needed every time a user wants
      # to preview the site, so must be built quickly.
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      ${pkgs.pandoc}/bin/pandoc -f docbook -t html <${file} >$out
    '';
    in builtins.readFile htmlFile;
}
