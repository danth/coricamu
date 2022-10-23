{ coricamu, lib, runCommand, symlinkJoin }:

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

in {
  page = runCommand "${coricamu.string.makeSlug title}.html" {} ''
    echo "<!DOCTYPE html>" >> $out
    echo "<body>" >> $out
    ${writeGroup "header"}
    ${writeGroup "main"}
    ${writeGroup "footer"}
    echo "</body>" >> $out
    echo "</html>" >> $out
  '';

  auxiliary = pipe groups [
    attrValues
    concatLists
    (catAttrs "auxiliary")
    (zipAttrsWith (path: files: elemAt files 0))
  ];
}
