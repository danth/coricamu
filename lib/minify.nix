{ coricamuLib, pkgsLib, pkgs, ... }:

with pkgsLib;
with coricamuLib;

let
  minifyCommands = {
    css = path: ''
      ${pkgs.nodePackages.clean-css-cli}/bin/cleancss \
        -O2 \
        -o ${path} ${path}
    '';

    html = path: ''
      ${pkgs.nodePackages.html-minifier}/bin/html-minifier \
        --collapse-boolean-attributes \
        --collapse-whitespace --conservative-collapse \
        --remove-comments \
        --remove-optional-tags \
        --remove-redundant-attributes \
        --remove-script-type-attributes \
        --remove-style-link-type-attributes \
        --sort-attributes \
        --sort-class-name \
        ${path} --output ${path}
    '';

    xml = path: ''
      ${pkgs.xmlformat}/bin/xmlformat -i ${path}
    '';
  };

in {
  minifyFileWithPath =
    path: file:
    let inherit (splitFilename path) baseName extension;
    in pkgs.runCommand "${baseName}.min.${extension}" { } ''
      cp --no-preserve=mode,ownership ${file} $out
      ${minifyCommands.${extension} "$out"}
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
        ${minifyCommands.${extension} "$target"}
      '';
    };
}
