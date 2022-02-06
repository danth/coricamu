{ pkgsLib, ... }:

with pkgsLib;

{
  makeSlug = text: pipe text [
    toLower
    (builtins.split "[^a-z0-9]+")
    (concatMapStrings (s: if isList s then "_" else s))
  ];
}
