{ allowNull ? false }:
{ coricamuLib, pkgsLib, config, name, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

let
  sourceFunctions = rec {
    html = id;

    htmlFile = builtins.readFile;

    markdown = source: convertMarkdown {
      inherit name;
      markdown = source;
    };

    markdownFile = source: convertMarkdownFile {
      inherit name;
      file = source;
    };

    docbook = source: convertDocbook {
      inherit name;
      docbook = source;
    };

    docbookFile = source: convertDocbookFile {
      inherit name;
      file = source;
    };
  };

  # Name of the source type which was used,
  # or NONE if no source was defined,
  # or MANY if multiple sources were defined
  usedSource = pipe sourceFunctions [
    attrNames
    (findSingle (name: config.${name} != null) "NONE" "MANY")
  ];

  # Names of all the source options, comma-separated
  sourceOptions = concatStringsSep ", " (attrNames sourceFunctions);

in {
  options = {
    html = mkOption {
      description = ''
        HTML content.

        May contain <literal>templates-«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be
        passed to the template as an attribute set, along with any HTML
        inside the tag as the <literal>contents</literal> attribute.
      '';
      example = ''
        <h1>Contact Us</h1>
        <p>You can reach us by contacting any of the following people:</p>
        <ul>
          <li><templates-user id="12345">Jane Doe</templates-user></li>
          <li><templates-user id="67890">John Doe</templates-user></li>
        </ul>
      '';
      type = nullOr lines;
      default = null;
    };

    htmlFile = mkOption {
      description = ''
        A file containing HTML.

        May contain <literal>templates-«name»</literal> tags which will call
        the corresponding template. HTML attributes (if present) will be
        passed to the template as an attribute set, along with any HTML
        inside the tag as the <literal>contents</literal> attribute.
      '';
      example = "./example.html";
      type = nullOr file;
      default = null;
    };

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

    output = mkOption {
      description = "Compiled HTML.";
      internal = true;
      readOnly = true;
      type = if allowNull then nullOr lines else lines;
    };
  };

  config.output =
    if usedSource == "NONE"
    then
      if allowNull
      then null
      else throw "One of ${sourceOptions} should be set"
    else if usedSource == "MANY"
    then throw "Only one of ${sourceOptions} can be set"
    else sourceFunctions.${usedSource} config.${usedSource};
}
