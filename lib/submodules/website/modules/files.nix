{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options = {
    files = mkOption {
      description = "Attribute set containing files by path.";
      type = attrsOf file;
      default = {};
    };

    minified = mkOption {
      description = "Whether to minify files in the output.";
      type = bool;
      default = true;
    };
  };


  config.package =
    let
      website = pkgs.linkFarm "website"
        (mapAttrsToList (name: path: { inherit name path; }) config.files);

      websiteMinified = pkgs.runCommand "website-minified" { } ''
        cp --recursive --dereference --no-preserve=mode,ownership ${website} website
        ${pkgs.minify}/bin/minify --all --sync --output minified --recursive website
        mv minified/website $out
      '';
    in
      if config.minified then websiteMinified else website;
}
