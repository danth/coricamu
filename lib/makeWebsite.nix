{ coricamu, lib, minify, runCommand, writeShellScript }:

with lib;

{
  baseUrl,
  title,
  files ? {},
  pages ? [],
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

  makeAuxiliaryArguments = mapAttrsToList (path: file: "${path} ${file}");

  makePageArguments = path: page:
    [ "${path} ${page.page}" ] ++
    (makeAuxiliaryArguments page.auxiliary);

in runCommand (coricamu.string.makeSlug baseUrl) {
  passAsFile = [ "arguments" ];
  arguments = concatStringsSep "\n" (
    (makeAuxiliaryArguments files) ++
    (concatLists (mapAttrsToList makePageArguments pages))
  );
} ''
  xargs \
    --arg-file="$argumentsPath" \
    --max-lines=1 \
    --max-procs="$NIX_BUILD_CORES" \
    --no-run-if-empty \
    ${if dontMinify then link else minifyOrLink}
''
