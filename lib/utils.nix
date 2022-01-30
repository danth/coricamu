{ pkgsLib, ... }:

with pkgsLib;

{
  mapAttrsToString = f: attrs: concatStringsSep "\n" (mapAttrsToList f attrs);
}
