{ pkgsLib, ... }:

with pkgsLib;

{
  notNull = value: !isNull value;

  mapAttrsToString = f: attrs: concatStringsSep "\n" (mapAttrsToList f attrs);

  escapeXML = replaceStrings
    ["\"" "'" "<" ">" "&"]
    ["&quot;" "&qpos;" "&lt;" "&gt;" "&amp;"];

  splitFilename =
    name:
    let list = builtins.match "(.*)\\.([a-z]+)" name;
    in {
      baseName = elemAt list 0;
      extension = elemAt list 1;
    };
}
