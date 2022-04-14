{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options.files = mkOption {
    description = "Attribute set containing files by path.";
    type = attrsOf file;
    default = {};
  };

  config.package = pkgs.linkFarm "website"
    (mapAttrsToList (name: path: { inherit name path; }) config.files);
}
