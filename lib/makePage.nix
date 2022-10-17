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
    ${pipe groups.${group} [
      (map (chunk: "cat ${chunk.file} >> $out"))
      (concatStringsSep "\n")
    ]}
    echo "</${group}>" >> $out
  '';

in runCommand "${coricamu.string.makeSlug title}.html" {} ''
  echo "<!DOCTYPE html>" >> $out
  echo "<body>" >> $out
  ${writeGroup "header"}
  ${writeGroup "main"}
  ${writeGroup "footer"}
  echo "</body>" >> $out
  echo "</html>" >> $out
''
