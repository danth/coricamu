{ coricamu, lib, minify, runCommand, writeShellScript }:

{
  baseUrl,
  title,
  files,
  dontMinify ? false
}:

let
  link = writeShellScript "link" ''
    mkdir -p "$(dirname "$out/$1")"
    ln -s "$2" "$out/$1"
    echo "Linked $1"
  '';

  minifyOrLink = writeShellScript "minify-or-link" ''
    if ${minify}/bin/minify \
      --type $extension \
      --html-keep-whitespace \
      --svg-keep-comments \
      --output "$out/$1" \
      "$2" \
      2>/dev/null
    then
      echo "Minified $1"
    else
      exec ${link} "$@"
    fi
  '';

in runCommand (coricamu.string.makeSlug baseUrl) {
  passAsFile = [ "arguments" ];
  arguments = with lib; pipe files [
    (mapAttrsToList (path: file: "${path} ${file}"))
    (concatStringsSep "\n")
  ];
} ''
  xargs \
    --arg-file="$argumentsPath" \
    --max-lines=1 \
    --max-procs="$NIX_BUILD_CORES" \
    --no-run-if-empty \
    ${if dontMinify then link else minifyOrLink}
''
