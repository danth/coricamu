{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

let
  allPosts = sort (a: b: a.datetime > b.datetime) config.posts;

  # { author: [post]; }
  authorPair = post: author: nameValuePair author [post];
  # { author_one: [post]; author_two: [post]; }
  postAuthors = post: listToAttrs (map (authorPair post) post.authors);
  # { author_one: [post_one post_two]; author_two: [post_one post_three]; }
  allAuthors = foldAttrs concat [] (map postAuthors allPosts);

  # If there is only one author then filtering is not useful
  authorIndexIsUseful = length (attrNames allAuthors) > 1;

  # { keyword: [post]; }
  keywordPair = post: keyword: nameValuePair keyword [post];
  # { keyword_one: [post]; keyword_two: [post]; }
  postKeywords = post: listToAttrs (map (keywordPair post) post.keywords);
  # { keyword_one: [post_one post_two]; keyword_two: [post_one post_three]; }
  allKeywords = foldAttrs concat [] (map postKeywords allPosts);

  # If there are zero or one keywords then filtering is not useful
  keywordIndexIsUseful = length (attrNames allKeywords) > 1;

  pillsIndexIsUseful = authorIndexIsUseful || keywordIndexIsUseful;

  indexConfig = {
    # There is no point having index pages appear on a search engine,
    # and they're not needed by the engine itself to discover other
    # pages because sitemap.xml exists
    meta.robots = "noindex";

    # Don't instruct search engines to look at the page
    sitemap.included = false;
  };

  makePostList = posts: ''
    <ol class="post-list">
      ${concatMapStringsSep "\n" (post: "<li>${post.indexEntry}</li>") posts}
    </ol>
  '';

in {
  options.posts = mkOption {
    description = "List of all posts.";
    type = listOf (post config);
    default = [];
  };

  config = {
    pages =
      # Individual posts
      catAttrs "page" allPosts

      # All posts chronologically
      ++ optional (length allPosts > 0) (indexConfig // rec {
        path = "posts/index.html";
        title = "All posts";
        body.html = ''
          <h1>${title}</h1>
          ${config.templates.posts-navigation {}}

          ${makePostList allPosts}
        '';
      })

      # Individual authors
      ++ optionals authorIndexIsUseful (mapAttrsToList (
        author: posts:
        indexConfig // rec {
          path = "posts/authors/${makeSlug author}.html";
          title = "Posts by ${author}";
          body.html = ''
            <h1>${title}</h1>
            ${config.templates.posts-navigation {}}

            ${makePostList posts}
          '';
        }
      ) allAuthors)

      # Individual keywords
      ++ optionals keywordIndexIsUseful (mapAttrsToList (
        keyword: posts:
        indexConfig // {
          path = "posts/keywords/${makeSlug keyword}.html";
          title = "Posts about \"${keyword}\"";

          # There is no point having this index appear on a search engine,
          # and it's not needed by the engine itself to discover other
          # pages because sitemap.xml exists
          meta.robots = "noindex";

          body.html = ''
            <h1>Posts about <q>${keyword}</q></h1>
            ${config.templates.posts-navigation {}}

            ${makePostList posts}
          '';
        }
      ) allKeywords)

      # All posts by author / keyword
      ++ optional pillsIndexIsUseful (indexConfig // rec {
        path = "posts/pills.html";
        title = "Posts index";

        body.html = ''
          <h1>${title}</h1>
          ${config.templates.posts-navigation {}}

          ${optionalString authorIndexIsUseful ''
            <h2>By author</h2>
            <ul class="pills">
              ${concatStringsSep "\n" (mapAttrsToList (author: posts:
                config.templates.author-pill { inherit author; }
              ) allAuthors)}
            </ul>
          ''}

          ${optionalString keywordIndexIsUseful ''
            <h2>By keyword</h2>
            <ul class="pills">
              ${concatStringsSep "\n" (mapAttrsToList (keyword: posts:
                config.templates.keyword-pill { inherit keyword; }
              ) allKeywords)}
            </ul>
          ''}
        '';
      });

    footer.html = mkIf (length allPosts > 0) (mkDefault ''
      <a class="rss-link" href="/rss/posts.xml">
        <svg
          class="rss-icon"
          aria-hidden="true"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 512 512"
        >
          <path d="M27.906 27.28v91.44a365.765 365.765 0 0 1 365.75 365.78h91.438A457.207 457.207 0 0 0 27.906 27.28zm0 154.157v88.813a214.234 214.234 0 0 1 214.22 214.25h88.843A303.063 303.063 0 0 0 27.905 181.437zM88.75 359.125a62.703 62.703 0 0 0-60.844 62.656 62.703 62.703 0 0 0 125.375 0 62.703 62.703 0 0 0-64.53-62.655z" />
        </svg>
        RSS feed
      </a>
    '');

    files."rss/posts.xml" = mkIf (length allPosts > 0) (writeMinified {
      name = "posts.xml";

      text = ''
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
          <channel>
            <atom:link
              href="${config.baseUrl}rss/posts.xml"
              rel="self"
              type="application/rss+xml"
            />
            <link>${config.baseUrl}posts/index.html</link>

            <language>${config.language}</language>
            <title>${escapeXML config.siteTitle}</title>
            <description>All posts from ${escapeXML config.siteTitle}.</description>
            <generator>Coricamu</generator>

            <pubDate>${
              # Date of latest post
              (elemAt allPosts 0).datetime
            }</pubDate>

            ${concatMapStringsSep "\n" (post: post.rssEntry) allPosts}
          </channel>
        </rss>
      '';

      # Convert all dates to RFC-822 format as required by RSS.
      checkPhase =
        let python = pkgs.python3.withPackages
          (ps: with ps; [ beautifulsoup4 dateutil ]);
        in "${python}/bin/python ${../rss_dates.py} $target $target";
    });

    templates = {
      all-posts = _: makePostList allPosts;

      recent-posts = { count }: makePostList (take (toInt count) allPosts);

      author-pill =
        { author, itemprop ? false }:
        if authorIndexIsUseful
        then ''
          <li
            ${optionalString itemprop "itemprop=\"author\""}
            itemscope
            itemtype="https://schema.org/Person"
          ><a
            itemprop="url"
            href="/posts/authors/${makeSlug author}.html"
            title="View all posts by ${author}"
            aria-label="View all posts by ${author}"
          ><span
            itemprop="name"
          >${author}</span></a></li>
        ''
        else ''
          <li
            ${optionalString itemprop "itemprop=\"author\""}
            itemscope
            itemtype="https://schema.org/Person"
          ><span
            itemprop="name"
          >${author}</span></li>
        '';

      keyword-pill =
        { keyword }:
        if keywordIndexIsUseful
        then ''
          <li><a
            href="/posts/keywords/${makeSlug keyword}.html"
            title="View all posts about &quot;${keyword}&quot;"
            aria-label="View all posts about &quot;${keyword}&quot;"
          >${keyword}</a></li>
        ''
        else ''
          <li>${keyword}</li>
        '';

      posts-navigation = _: ''
        <nav class="post-explore">
          Explore
          <a href="/posts/index.html">all posts</a>
          ${optionalString pillsIndexIsUseful ''
            or the <a href="/posts/pills.html">index</a>
          ''}
        </nav>
      '';
    };
  };
}