{ lib, pkgs, config, ... }:

with lib;
with types;

{
  options = {
    package = mkOption {
      description = "Derivation containing the web root.";
      type = package;
      internal = true;
    };

    files = mkOption {
      description = "Attribute set containing files by path.";
      type = attrsOf package;
    };
  };

  config.package = pkgs.linkFarm "website"
    (mapAttrsToList (name: path: { inherit name path; }) config.files);
}
