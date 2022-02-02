{ coricamuLib, pkgsLib, config, name, templates, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;

let
  sourceFunctions = rec {
    html = source: fillTemplates {
      html = source;
      inherit name templates;
    };

    markdown = source: html (convertMarkdown {
      inherit name;
      markdown = source;
    });
  };

  # Name of the source type which was used,
  # or NONE if no source was defined,
  # or MANY if multiple sources were defined
  usedSource = pipe sourceFunctions [
    attrNames
    (findSingle (name: notNull config.${name}) "NONE" "MANY")
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

        Note: image sources and other links in your HTML are relative to the
        root of the website, whereas usually they would be relative to the
        current page. Therefore, it's recommended not to add a
        <literal>/</literal> at the beginning of relative links, so that the
        website can render correctly when it is previewed locally.
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

        Note: image sources and other links in your Markdown are relative to
        the root of the website, whereas usually they would be relative to the
        current page. Therefore, it's recommended not to add a
        <literal>/</literal> at the beginning of relative links, so that the
        website can render correctly when it is previewed locally.
      '';
      example = ''
        # Contact Us

        You can reach us by contacting any of the following people:

        - <templates.user id="12345">Jane Doe</templates.user>
        - <templates.user id="67890">John Doe</templates.user>
      '';
      type = nullOr lines;
      default = null;
    };

    output = mkOption {
      description = "Compiled HTML.";
      internal = true;
      readOnly = true;
      type = lines;
    };
  };

  config.output =
    if usedSource == "NONE"
    then throw "One of ${sourceOptions} should be set"
    else if usedSource == "MANY"
    then throw "Only one of ${sourceOptions} can be set"
    else sourceFunctions.${usedSource} config.${usedSource};
}