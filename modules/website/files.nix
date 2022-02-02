{ pkgsLib, pkgs, config, ... }:

with pkgsLib;
with types;

{
  options.files = mkOption {
    description = "Attribute set containing files by path.";
    type = attrsOf (either package path);
    default = {};
  };

  config.package = pkgs.linkFarm "website"
    (mapAttrsToList (name: path: { inherit name path; }) config.files);
}
