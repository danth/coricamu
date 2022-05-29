{ pkgsLib, coricamuLib, config, pkgs, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

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

  convertSassFile =
    sourceFile: isSCSS:
    pkgs.runCommand config.path { } ''
      ${pkgs.sass}/bin/sass \
        ${optionalString isSCSS "--scss"} \
        --sourcemap=none \
        ${sourceFile} $out
    '';

  sourceFunctions = rec {
    css = pkgs.writeText config.path;
    cssFile = id;

    scss = source: convertSass source true;
    scssFile = source: convertSassFile source true;

    sass = source: convertSass source false;
    sassFile = source: convertSassFile source false;
  };

  # Name of the source type which was used,
  # or NONE if no source was defined,
  # or MANY if multiple sources were defined
  usedSource = pipe sourceFunctions [
    attrNames
    (findSingle (name: config.${name} != null) "NONE" "MANY")
  ];

  # Names of all the source options, comma-separated
  sourceOptions = concatStringsSep ", " (attrNames sourceFunctions);

in {
  options = {
    css = mkOption {
      description = "CSS code.";
      type = nullOr lines;
      default = null;
    };

    cssFile = mkOption {
      description = "CSS code as a file.";
      type = nullOr file;
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

    scssFile = mkOption {
      description = ''
        SCSS style sheet as a file.

        This will be automatically converted to CSS.
      '';
      type = nullOr file;
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

    sassFile = mkOption {
      description = ''
        Sass style sheet as a file.

        This will be automatically converted to CSS.
      '';
      type = nullOr file;
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
      type = file;
    };
  };

  config.output =
    if usedSource == "NONE"
    then throw "One of ${sourceOptions} should be set"
    else if usedSource == "MANY"
    then throw "Only one of ${sourceOptions} can be set"
    else sourceFunctions.${usedSource} config.${usedSource};
}
