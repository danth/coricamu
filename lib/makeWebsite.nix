{ coricamu, lib, minify, runCommand, writeShellScript }:

with lib;

{
  baseUrl,
  files ? [],
  commonChunks ? [],
  dontMinify ? false
}:

let
  nameSlug = coricamu.string.makeSlug baseUrl;

  root = coricamu.makeSubdirectory {
    name = nameSlug;
    inherit files commonChunks;
    isRoot = true;
  };

  finalizeFile = file:
    if builtins.isPath file
    then file
    else if file.type == "derivation"
    then file
    else if file.type == "page"
    then file.file
    else throw "Invalid file: ${file}";

  link = path: file: ''
    mkdir -p $out/${escapeShellArg (dirOf path)}
    ln -s ${finalizeFile file} $out/${escapeShellArg path}
    echo Linked ${escapeShellArg path}
  '';

  minifyOrLink = path: file: ''
    if ${minify}/bin/minify \
      --html-keep-whitespace \
      --svg-keep-comments \
      --output $out/${escapeShellArg path} \
      ${finalizeFile file} \
      2>/dev/null
    then
      echo Minified ${escapeShellArg path}
    else
      ${link path file}
    fi
  '';

  include = if dontMinify then link else minifyOrLink;

  build = concatStringsSep "\n" (mapAttrsToList include root);

in runCommand nameSlug { } build
