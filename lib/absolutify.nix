{ pkgs, ... }:

{
  absolutifyCommand =
    { file, baseUrl, path }:
    let python = pkgs.python3.withPackages (ps: [ ps.beautifulsoup4 ]);
    in ''
      ${python}/bin/python ${./absolutify.py} \
        ${file} $out "${baseUrl}${path}"
    '';
}
