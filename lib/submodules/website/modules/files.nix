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


  config.package = pkgs.runCommand "website-minified" {
    source = pkgs.linkFarm "website"
      (mapAttrsToList (name: path: { inherit name path; }) config.files);
  } ''
    cp --recursive --dereference --no-preserve=mode,ownership $source website
    ${pkgs.minify}/bin/minify --all --sync --output minified --recursive website
    mv minified/website $out
  '';
}
