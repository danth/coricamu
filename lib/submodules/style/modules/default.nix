{ pkgsLib, coricamuLib, config, pkgs, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;

let
  convertSass =
    source: isSCSS:
    pkgs.runCommand config.path {
      inherit source;
      passAsFile = [ "source" ];
    } ''
      ${pkgs.sass}/bin/sass \
        ${optionalString isSCSS "--scss"} \
        --sourcemap=none \
        $sourcePath $out
    '';

  sourceFunctions = rec {
    css = source: writeMinified {
      name = config.path;
      text = source;
    };
    scss = source: minifyFile (convertSass source true);
    sass = source: minifyFile (convertSass source false);
  };

  # Name of the source type which was used,
  # or NONE if no source was defined,
  # or MANY if multiple sources were defined
  usedSource = pipe sourceFunctions [
    attrNames
    (findSingle (name: notNull config.${name}) "NONE" "MANY")
  ];

  # Names of all the source options, comma-separated
  sourceOptions = concatStringsSep ", " (attrNames sourceFunctions);

in {
  options = {
    css = mkOption {
      description = "CSS style sheet.";
      type = nullOr lines;
      default = null;
    };

    scss = mkOption {
      description = ''
        SCSS style sheet.

        This will be automatically converted to CSS.
      '';
      type = nullOr lines;
      default = null;
    };

    sass = mkOption {
      description = ''
        Sass style sheet.

        This will be automatically converted to CSS.
      '';
      type = nullOr lines;
      default = null;
    };

    path = mkOption {
      description = "Path of the style sheet relative to the root URL.";
      type = strMatching ".*\\.css";
    };

    output = mkOption {
      description = "CSS file.";
      internal = true;
      readOnly = true;
      type = package;
    };
  };

  config.output =
    if usedSource == "NONE"
    then throw "One of ${sourceOptions} should be set"
    else if usedSource == "MANY"
    then throw "Only one of ${sourceOptions} can be set"
    else sourceFunctions.${usedSource} config.${usedSource};
}
