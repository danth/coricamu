{ lib }:

with lib;

string:

pipe string [
  toLower
  (builtins.split "[^a-z0-9]+")
  (concatMapStrings (s: if isList s then "_" else s))
]
