{ pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;

{
  options = {
    path = mkOption {
      description = "Path of the image relative to the root URL.";
      type = strMatching ".+\\..+";
    };

    file = mkOption {
      description = "The image.";
      type = either path package;
    };

    outputFile = mkOption {
      description = "Optimised version of the image.";
      internal = true;
      readOnly = true;
      type = package;
    };
  };

  config.outputFile =
    pkgs.runCommand
    config.path
    {
      optim = pkgs.image_optim.override {
        # Disabled due to unfree license
        withPngout = false;
      };
      optimConfig = ''
        nice: 0
        pngout: false
        allow_lossy: true
      '';
      passAsFile = [ "optimConfig" ];
    }
    ''
      cp ${config.file} $out

      ln -s $optimConfigPath .image_optim.yml
      $optim/bin/image_optim --no-progress $out
    '';
}
