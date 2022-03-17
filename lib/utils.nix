{ pkgsLib, ... }:

with pkgsLib;

{
  escapeXML = replaceStrings
    ["\"" "'" "<" ">" "&"]
    ["&quot;" "&qpos;" "&lt;" "&gt;" "&amp;"];

  makeSlug = text: pipe text [
    toLower
    (builtins.split "[^a-z0-9]+")
    (concatMapStrings (s: if isList s then "_" else s))
  ];

  mapAttrsToString = f: attrs: concatStringsSep "\n" (mapAttrsToList f attrs);

  splitFilename =
    name:
    let list = builtins.match "(.*)\\.([a-z]+)" name;
    in {
      baseName = elemAt list 0;
      extension = elemAt list 1;
    };
}
