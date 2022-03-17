{ coricamuLib, pkgs, ... }:

with coricamuLib;

{
  absolutifyUrls =
    { name, html, baseUrl }:
    minifyFile (pkgs.runCommand name {
      inherit html;
      passAsFile = [ "html" ];
    } ''
      ${pkgs.coricamu.absolutify-urls}/bin/absolutify-urls \
        "${baseUrl}" <$htmlPath >$out
    '');
}

