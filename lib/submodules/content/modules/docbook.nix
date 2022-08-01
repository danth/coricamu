{ coricamuLib, pkgsLib, pkgs, config, name, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

let
  converted =
    let htmlFile = pkgs.runCommand "${name}.html" {
      inherit (config) docbook;
      passAsFile = [ "docbook" ];
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      ${pkgs.pandoc}/bin/pandoc -f docbook -t html <$docbookPath >$out
    '';
    in builtins.readFile htmlFile;

  convertedFile =
    let htmlFile = pkgs.runCommand "${name}.html" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      ${pkgs.pandoc}/bin/pandoc -f docbook -t html <${config.docbookFile} >$out
    '';
    in builtins.readFile htmlFile;

in {
  options = {
    docbook = mkOption {
      description = "DocBook content.";
      example = ''
        <title>Contact Us</title>
        <para>You can reach us by contacting any of the following people:</para>
        <itemizedlist>
          <listitem><para>Jane Doe</para></listitem>
          <listitem><para>John Doe</para></listitem>
        </itemizedlist>
      '';
      type = nullOr lines;
      default = null;
    };

    docbookFile = mkOption {
      description = "A file containing DocBook.";
      example = "./example.xml";
      type = nullOr file;
      default = null;
    };
  };

  config.outputs =
    optional (config.docbook != null) converted
    ++ optional (config.docbookFile != null) convertedFile;
}
