{ coricamu, lib, minify, runCommand, writeShellScript }:

with lib;

{
  baseUrl,
  files ? [],
  dontMinify ? false
}:

let
  nameSlug = coricamu.string.makeSlug baseUrl;

  root = coricamu.makeSubdirectory {
    name = nameSlug;
    inherit files;
    isRoot = true;
  };
  root' = removeAttrs root ["override" "overrideDerivation"];

  link = path: file: ''
    mkdir -p $out/${escapeShellArg (dirOf path)}
    ln -s ${file} $out/${escapeShellArg path}
    echo Linked ${escapeShellArg path}
  '';

  minifyOrLink = path: file: ''
    if ${minify}/bin/minify \
      --html-keep-whitespace \
      --svg-keep-comments \
      --output $out/${escapeShellArg path} \
      ${file} \
      2>/dev/null
    then
      echo Minified ${escapeShellArg path}
    else
      ${link path file}
    fi
  '';

  include = if dontMinify then link else minifyOrLink;

  build = concatStringsSep "\n" (mapAttrsToList include root');

in runCommand nameSlug { } build
