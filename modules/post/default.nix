{ coricamuLib, pkgsLib, config, websiteConfig, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;

{
  options = {
    datetime = mkOption {
      description = "Date and time of this post.";
      example = "2022-01-31 20:10:05";
      type =
        let pattern =
          "[0-9]{4}-[0-9]{2}-[0-9]{2}([T ][0-9]{2}(:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2}|[0-9]{4})?)?)?)?";
        in mkOptionType {
          name = "HTML datetime";
          description = "YYYY-MM-DDThh:mm:ssTZD";
          check = x: str.check x && builtins.match pattern x != null;
          inherit (str) merge;
        };
    };

    title = mkOption {
      description = "Title of the post.";
      example = "Lorem Ipsum";
      type = str;
    };

    slug = mkOption {
      description = "Simplified title suitable for use as a file name.";
      example = "lorem_ipsum";
      type = strMatching "[a-z0-9_]+";
      default = pipe config.title [
        toLower
        (builtins.split "[^a-z0-9]+")
        (concatMapStrings (s: if isList s then "_" else s))
      ];
    };

    body = mkOption {
      description = ''
        HTML body of the post.

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
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
        eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
        minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip
        ex ea commodo consequat. Duis aute irure dolor in reprehenderit in
        voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur
        sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.</p>
      '';
      type = lines;
    };

    markdownBody = mkOption {
      description = ''
        Markdown body of the post.

        May contain <literal>templates.«name»</literal> HTML tags in places
        where Markdown allows embedded HTML. This will call the corresponding
        template. HTML attributes (if present) will be passed to the template
        as an attribute set, along with any converted Markdown inside the tag
        as the <literal>contents</literal> attribute. Template tags are not
        guaranteed to work in all places when using Markdown - if you need more
        flexibility, consider writing the post directly in HTML instead.

        Note: image sources and other links in your Markdown are relative to
        the root of the website, whereas usually they would be relative to the
        current page. Therefore, it's recommended not to add a
        <literal>/</literal> at the beginning of relative links, so that the
        website can render correctly when it is previewed locally.

        Markdown will be inserted to <literal>body</literal> after it is
        converted. If you set <literal>body</literal> to something else, it
        will override the Markdown; therefore, it's recommended to only use
        either <literal>body</literal> or <literal>markdownBody</literal>, not
        both.
      '';
      example = ''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
        commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
        velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia deserunt
        mollit anim id est laborum.
      '';
      type = nullOr lines;
      default = null;
    };


    page = mkOption {
      description = ''
        Main page definition for this post.

        Can be used to set any page settings which aren't automatically filled.
      '';
      example = {
        meta.keywords = "post, key, words";
      };
      # Causes page.file to be defined twice otherwise
      type = unspecified;
    };
  };

  config = let
    # Extract only the date
    date = substring 0 10 config.datetime;
  in {
    body = mkIf
      (!(isNull config.markdownBody))
      (convertMarkdown {
        name = "${config.slug}-source";
        markdown = config.markdownBody;
      });

    page = {
      path = "posts/${config.slug}.html";

      inherit (config) title;

      body = ''
        <article>
          <h1>${config.title}</h1>
          <small>Posted on
          <time datetime="${config.datetime}">${date}</time>.</small>

          ${config.body}
        </article>
      '';

      sitemap.lastModified = date;
    };
  };
}
