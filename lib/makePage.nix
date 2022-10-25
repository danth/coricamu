{ coricamu, lib, runCommand }:

with lib;

{
  title,
  name ? coricamu.string.makeSlug title,
  chunks ? []
}:

let
  groups = groupBy (chunk: chunk.type) chunks;

  writeGroup = group: optionalString (groups ? ${group}) ''
    echo "<${group}>" >> $out
    ${concatStringsSep "\n" (catAttrs "buildCommand" groups.${group})}
    echo "</${group}>" >> $out
  '';

  page = {
    type = "page";

    file = runCommand "${name}.html" {} ''
      echo "<!DOCTYPE html>" >> $out
      ${writeGroup "head"}
      echo "<body>" >> $out
      ${writeGroup "header"}
      ${writeGroup "main"}
      ${writeGroup "footer"}
      echo "</body>" >> $out
      echo "</html>" >> $out
    '';

    addChunks = newChunks: coricamu.makePage {
      inherit title name;
      chunks = chunks ++ newChunks;
    };
  };

in coricamu.mergeFiles (
  [{
    "${name}.html" = page;
  }] ++ 
  (pipe groups [
    attrValues
    concatLists
    (catAttrs "auxiliaryFiles")
  ])
)
