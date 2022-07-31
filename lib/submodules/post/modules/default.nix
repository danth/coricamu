{ coricamuLib, pkgsLib, config, websiteConfig, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

let datetime =
  let pattern =
    "[0-9]{4}-[0-9]{2}-[0-9]{2}([T ][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}:[0-9]{2}|[+-][0-9]{4})?)?";
  in mkOptionType {
    name = "HTML datetime";
    description = "YYYY-MM-DDThh:mm:ssTZD";
    check = x: str.check x && builtins.match pattern x != null;
    inherit (str) merge;
  };

in {
  options = {
    datetime = mkOption {
      description = "Date and time of this post.";
      example = "2022-01-31 20:10:05";
      type = datetime;
    };

    edited = mkOption {
      description = "Date and time this post was last edited.";
      example = "2022-03-10 07:50:40";
      type = nullOr datetime;
      default = null;
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
      default = makeSlug config.title;
      defaultText = literalDocBook "Generated from the post title.";
    };

    authors = mkOption {
      description = "Names of the author(s) of this post.";
      example = [ "John Doe" "Jane Doe" ];
      type = listOf str;
    };

    keywords = mkOption {
      description = "Key words or phrases related to this post.";
      example = [ "lorem" "ipsum dolor" ];
      type = listOf str;
      default = [];
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
      type = content {};
    };

    indexEntry = mkOption {
      description = "Entry in the posts index page for this post.";
      internal = true;
      type = lines;
    };

    rssEntry = mkOption {
      description = "Entry in the RSS feed for this post.";
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
    datePosted = substring 0 10 config.datetime;
    dateEdited = substring 0 10 config.edited;

    authors = sort (a: b: a < b) config.authors;
    keywords = sort (a: b: a < b) config.keywords;

    postInfo = ''
      Posted
      <templates-relative-time-pill
        itemprop="datePublished"
        datetime="${config.datetime}" />

      ${optionalString (config.edited != null) ''
        and edited
        <templates-relative-time-pill
          itemprop="dateModified"
          datetime="${config.edited}" />
      ''}

      by
      <ul class="pills">
        ${
          concatMapStringsSep "\n"
          (author: ''
            <templates-author-pill author="${author}" itemprop="true" />
          '')
          authors
        }
      </ul>

      ${optionalString (length keywords > 0) ''
        with keywords
        <ul itemprop="keywords" class="pills">
          ${
            concatMapStringsSep "\n"
            (keyword: ''
              <templates-keyword-pill keyword="${keyword}" />
            '')
            keywords
          }
        </ul>
      ''}
    '';

  in {
    indexEntry = ''
      <section
        itemscope
        itemtype="https://schema.org/BlogPosting"
        class="post-summary"
      >
        <a itemprop="url"
           href="${config.page.path}"
        ><h1 itemprop="headline">${config.title}</h1></a>
        ${
          optionalString
          (config.page.meta ? description)
          "<p itemprop=\"abstract\">${config.page.meta.description}</p>"
        }
        <div class="post-meta">${postInfo}</div>
      </section>
    '';

    rssEntry =
      let
        # This pattern will only match if both a time and timezone are present.
        pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}:[0-9]{2}|[+-][0-9]{4})";
        match = builtins.match pattern config.datetime;
        showWarning = if match != null then id else warn
            "Specify a time with a time zone for \"${config.title}\" to increase compatibility with RSS feed readers.";

        link = "${websiteConfig.baseUrl}${config.page.path}";

      in showWarning ''
        <item>
          <guid isPermaLink="true">${link}</guid>
          <link>${link}</link>
          <pubDate>${config.datetime}</pubDate>
          <title>${escapeXML config.title}</title>
          ${
            optionalString
            (config.page.meta ? description)
            "<description>${escapeXML config.page.meta.description}</description>"
          }
        </item>
      '';

    page = {
      path = "posts/post/${config.slug}.html";

      inherit (config) title;

      body.html = ''
        <article
          itemscope
          itemtype="https://schema.org/BlogPosting"
          class="post"
        >
          <h1 itemprop="headline">${config.title}</h1>
          <div itemprop="articleBody">
            ${config.body.output}
          </div>
          <footer class="post-meta">
            ${postInfo}
            <link itemprop="url" href="${config.page.path}">
            <templates-posts-navigation />
          </footer>
        </article>
      '';

      meta = {
        author = concatStringsSep ", " config.authors;
        keywords = concatStringsSep ", " keywords;
      };

      sitemap.lastModified =
        if (config.edited == null) then datePosted else dateEdited;
    };
  };
}
