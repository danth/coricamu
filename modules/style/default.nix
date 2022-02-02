{ pkgsLib, pkgs, config, name, ... }:

with pkgsLib;
with types;

{
  options = {
    path = mkOption {
      description = "Path of the style sheet relative to the root URL.";
      type = strMatching ".*\\.css";
    };

    css = mkOption {
      description = "Lines of CSS code for this style sheet.";
      type = types.lines;
    };

    file = mkOption {
      description = ''
        CSS file for this style sheet.

        By default this is created by writing <literal>body</literal> to a
        file. If this is set, <literal>body</literal> will be ignored and this
        file used instead. You should only set one of <literal>body</literal>
        or <literal>file</literal>.
      '';
      type = either path package;
    };
  };

  config.file =
    mkDefault
    (pkgs.writeTextFile {
      name = "${name}.css";
      text = config.css;
    });
}
