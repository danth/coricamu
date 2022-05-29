{ pkgsLib, coricamuLib, config, pkgs, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

let
  sourceFunctions = rec {
    javascript = source: writeMinified {
      name = config.path;
      text = source;
    };
    javascriptFile = minifyFileWithPath config.path;
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
    javascript = mkOption {
      description = "JavaScript code.";
      type = nullOr lines;
      default = null;
    };

    javascriptFile = mkOption {
      description = "JavaScript code as a file.";
      type = nullOr file;
      default = null;
    };

    path = mkOption {
      description = "Path of the script relative to the root URL.";
      type = strMatching ".*\\.js";
    };

    output = mkOption {
      description = "JavaScript file.";
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
