{ coricamu, lib, runCommand }:

with lib;

{
  title,
  chunks ? []
}:

let
  groups = groupBy (chunk: chunk.type) chunks;

  writeGroup = group: optionalString (groups ? ${group}) ''
    echo "<${group}>" >> $out
    ${concatStringsSep "\n" (catAttrs "buildCommand" groups.${group})}
    echo "</${group}>" >> $out
  '';

  filename = "${coricamu.string.makeSlug title}.html";

in coricamu.mergeFiles (
  [{
    ${filename} = runCommand filename {} ''
      echo "<!DOCTYPE html>" >> $out
      echo "<body>" >> $out
      ${writeGroup "header"}
      ${writeGroup "main"}
      ${writeGroup "footer"}
      echo "</body>" >> $out
      echo "</html>" >> $out
    '';
  }] ++ 
  (pipe groups [
    attrValues
    concatLists
    (catAttrs "auxiliaryFiles")
  ])
)
