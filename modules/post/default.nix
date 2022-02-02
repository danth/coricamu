{ coricamuLib, pkgsLib, config, websiteConfig, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

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

    authors = mkOption {
      description = "Names of the author(s) of this post.";
      example = [ "John Doe" "Jane Doe" ];
      type = listOf str;
    };

    body = mkOption {
      description = "Main post content.";
      example.markdown = ''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
        eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
        minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip
        ex ea commodo consequat. Duis aute irure dolor in reprehenderit in
        voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur
        sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.
      '';
      type = content websiteConfig.templates;
    };

    indexEntry = mkOption {
      description = "Entry in the posts index page for this post.";
      internal = true;
      type = lines;
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

    postInfo = ''
      <p>
        Posted on
        <time
          itemprop="datePublished"
          datetime="${config.datetime}"
        >${date}</time>
        by ${
          concatStringsSep " and " (map
            (author: "<span itemprop=\"author\">${author}</span>")
          config.authors)
        }
      </p>
    '';

  in {
    indexEntry = ''
      <article itemscope itemtype="https://schema.org/BlogPosting">
        <a itemprop="url"
           href="${websiteConfig.baseUrl}${config.page.path}"
        ><h2 itemprop="headline">${config.title}</h2></a>
        ${postInfo}
      </article>
    '';

    page = {
      path = "posts/${config.slug}.html";

      inherit (config) title;

      body.html = ''
        <article itemscope itemtype="https://schema.org/BlogPosting">
          <link itemprop="url"
                href="${websiteConfig.baseUrl}${config.page.path}">
          <h1 itemprop="headline">${config.title}</h1>
          ${postInfo}
          <div itemprop="articleBody">${config.body.output}</div>
        </article>
      '';

      meta.author = concatStringsSep ", " config.authors;

      sitemap.lastModified = date;
    };
  };
}
