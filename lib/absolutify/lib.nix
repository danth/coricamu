{ coricamuLib, pkgs, ... }:

with coricamuLib;

let
  python = pkgs.python3.withPackages (ps: [ ps.beautifulsoup4 ]);

in {
  absolutifyUrls =
    { name, html, baseUrl, checkPhase ? "" }:
    writeMinified {
      inherit name;
      text = html;
      # Convert relative paths into absolute URLs
      checkPhase = ''
        ${python}/bin/python ${./absolutify.py} \
          $target $target "${baseUrl}"

        ${checkPhase}
      '';
    };
}
