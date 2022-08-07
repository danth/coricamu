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

      websiteMinified = pkgs.runCommand "website-minified" {
        passAsFile = [ "arguments" ];
        arguments = pipe config.files [
          (mapAttrsToList (path: file: "${path} ${file}"))
          (concatStringsSep "\n")
        ];
      } ''
        export supportedTypes=$(${pkgs.minify}/bin/minify --list | cut -f 1)

        function buildFile {
          extension="''${1##*.}"
          if [[ "$supportedTypes" =~ (^|[[:space:]])$extension($|[[:space:]]) ]]
          then
            echo "Minifying $1"
            ${pkgs.minify}/bin/minify \
              --type $extension \
              --html-keep-whitespace \
              --svg-keep-comments \
              --output "$out/$1" "$2"
          else
            echo "Linking $1"
            mkdir -p "$(dirname "$out/$1")"
            ln -s "$2" "$out/$1"
          fi
        }
        export -f buildFile

        xargs \
          -a $argumentsPath -d '\n' \
          -r -l -P $NIX_BUILD_CORES \
          bash -c 'buildFile $1 $2' {}
      '';
    in
      if config.minified then websiteMinified else website;
}
