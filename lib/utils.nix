{ pkgsLib, ... }:

with pkgsLib;

{
  notNull = value: !isNull value;

  mapAttrsToString = f: attrs: concatStringsSep "\n" (mapAttrsToList f attrs);
}
