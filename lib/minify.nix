{ coricamuLib, pkgsLib, pkgs, ... }:

with pkgsLib;
with coricamuLib;

let
  minifyCommand = format: path:
    "${pkgs.minify}/bin/minify --type ${format} --output ${path} ${path}";

in {
  minifyFileWithPath =
    path: file:
    let inherit (splitFilename path) baseName extension;
    in pkgs.runCommand "${baseName}.min.${extension}" { } ''
      cp --no-preserve=mode,ownership ${file} $out
      ${minifyCommand extension "$out"}
    '';

  minifyFile =
    file: minifyFileWithPath file.name file;

  writeMinified =
    { name, text, checkPhase ? "" }:
    let inherit (splitFilename name) baseName extension;
    in pkgs.writeTextFile {
      name = "${baseName}.min.${extension}";
      inherit text;
      checkPhase = ''
        ${checkPhase}
        ${minifyCommand extension "$target"}
      '';
    };
}
