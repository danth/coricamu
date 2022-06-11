{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options = {
    path = mkOption {
      description = "Path of the optimised image relative to the root URL.";
      type = strMatching ".+\\.webp";
    };

    file = mkOption {
      description = "The image.";
      type = file;
    };

    outputFile = mkOption {
      description = "Optimised version of the image.";
      internal = true;
      readOnly = true;
      type = package;
    };
  };

  config.outputFile =
    pkgs.runCommand config.path { } ''
      ${pkgs.imagemagick}/bin/convert ${config.file} $out
    '';
}
