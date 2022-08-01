{ coricamuLib, pkgsLib, pkgs, config, name, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

let
  converted =
    let htmlFile = pkgs.runCommand "${name}.html" {
      inherit (config) markdown;
      passAsFile = [ "markdown" ];
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      ${pkgs.multimarkdown}/bin/multimarkdown \
        --snippet --notransclude \
        --to=html --output=$out $markdownPath
    '';
    in builtins.readFile htmlFile;

  convertedFile =
    let htmlFile = pkgs.runCommand "${name}.html" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      ${pkgs.multimarkdown}/bin/multimarkdown \
        --snippet --notransclude \
        --to=html --output=$out ${config.markdownFile}
    '';
    in builtins.readFile htmlFile;

in {
  options = {
    markdown = mkOption {
      description = ''
        Markdown content.

        May contain <literal>templates.«name»</literal> HTML tags in places
        where Markdown allows embedded HTML. This will call the corresponding
        template. HTML attributes (if present) will be passed to the template
        as an attribute set, along with any converted Markdown inside the tag
        as the <literal>contents</literal> attribute. Template tags are not
        guaranteed to work in all places when using Markdown - if you need more
        flexibility, consider writing in pure HTML instead.

        This uses MultiMarkdown, which is an extension to the common Markdown
        syntax. A full cheat sheet can be found on
        <link xlink:href="https://rawgit.com/fletcher/MultiMarkdown-6-Syntax-Guide/master/index.html">the MultiMarkdown website</link>.
      '';
      example = ''
        # Contact Us

        You can reach us by contacting any of the following people:

        - <templates-user id="12345">Jane Doe</templates.user>
        - <templates-user id="67890">John Doe</templates.user>
      '';
      type = nullOr lines;
      default = null;
    };

    markdownFile = mkOption {
      description = ''
        A file containing Markdown.

        May contain <literal>templates.«name»</literal> HTML tags in places
        where Markdown allows embedded HTML. This will call the corresponding
        template. HTML attributes (if present) will be passed to the template
        as an attribute set, along with any converted Markdown inside the tag
        as the <literal>contents</literal> attribute. Template tags are not
        guaranteed to work in all places when using Markdown - if you need more
        flexibility, consider writing in pure HTML instead.

        This uses MultiMarkdown, which is an extension to the common Markdown
        syntax. A full cheat sheet can be found on
        <link xlink:href="https://rawgit.com/fletcher/MultiMarkdown-6-Syntax-Guide/master/index.html">the MultiMarkdown website</link>.
      '';
      example = "./example.md";
      type = nullOr file;
      default = null;
    };
  };

  config.outputs =
    optional (config.markdown != null) converted
    ++ optional (config.markdownFile != null) convertedFile;
}
