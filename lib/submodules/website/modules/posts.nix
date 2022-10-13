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

  # { section: [post]; }
  sectionPair = post: section: nameValuePair section [post];
  # { section_one: [post]; section_two: [post]; }
  postSections = post: listToAttrs (map (sectionPair post) post.sections);
  # { section_one: [post_one post_two]; section_two: [post_one post_three]; }
  allSections = foldAttrs concat [] (map postSections allPosts);

  # If there are no sections then filtering is not useful
  sectionIndexIsUseful = length (attrNames allSections) > 0;

  pillsIndexIsUseful = authorIndexIsUseful || sectionIndexIsUseful;

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

  makeRSS = { path, title, description, posts }: pkgs.writeTextFile {
    name = path;

    text = ''
      <?xml version="1.0" encoding="UTF-8" ?>
      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <atom:link
            href="${config.baseUrl}${path}"
            rel="self"
            type="application/rss+xml"
          />
          <link>${config.baseUrl}posts/index.html</link>

          <language>${config.language}</language>
          <title>${escapeXML title}</title>
          <description>${escapeXML description}</description>
          <generator>Coricamu</generator>

          <pubDate>${
            # Date of latest post
            (elemAt allPosts 0).datetime
          }</pubDate>

          ${concatMapStringsSep "\n" (post: post.rssEntry) posts}
        </channel>
      </rss>
    '';

    # Convert all dates to RFC-822 format as required by RSS.
    checkPhase =
      let python = pkgs.python3.withPackages
        (ps: with ps; [ beautifulsoup4 dateutil ]);
      in "${python}/bin/python ${../rss_dates.py} $target $target";
  };

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
          <templates-posts-navigation />
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
            <templates-posts-navigation
              rss-path="authors/${makeSlug author}.xml"
              rss-label="this author's RSS feed" />
            ${makePostList posts}
          '';
        }
      ) allAuthors)

      # Individual sections
      ++ optionals sectionIndexIsUseful (mapAttrsToList (
        section: posts:
        indexConfig // {
          path = "posts/sections/${makeSlug section}.html";
          title = "Posts in section \"${section}\"";

          # There is no point having this index appear on a search engine,
          # and it's not needed by the engine itself to discover other
          # pages because sitemap.xml exists
          meta.robots = "noindex";

          body.html = ''
            <h1>Posts in section <q>${section}</q></h1>
            <templates-posts-navigation
              rss-path="sections/${makeSlug section}.xml"
              rss-label="this section's RSS feed" />
            ${makePostList posts}
          '';
        }
      ) allSections)

      # All posts by author / section
      ++ optional pillsIndexIsUseful (indexConfig // rec {
        path = "posts/pills.html";
        title = "Posts index";

        body.html = ''
          <h1>${title}</h1>
          <templates-posts-navigation />

          ${optionalString authorIndexIsUseful ''
            <h2>By author</h2>
            <ul class="pills">
              ${concatStringsSep "\n" (mapAttrsToList (author: _posts: ''
                <templates-author-pill author="${author}" />
              '') allAuthors)}
            </ul>
          ''}

          ${optionalString sectionIndexIsUseful ''
            <h2>By section</h2>
            <ul class="pills">
              ${concatStringsSep "\n" (mapAttrsToList (section: _posts: ''
                <templates-section-pill section="${section}" />
              '') allSections)}
            </ul>
          ''}
        '';
      });

    files =
      optionalAttrs (length allPosts > 0) {
        "posts/rss/index.xml" = makeRSS {
          path = "posts/rss/index.xml";
          title = config.siteTitle;
          description = "All posts from ${config.siteTitle}.";
          posts = allPosts;
        };
      }
      // optionalAttrs authorIndexIsUseful (mapAttrs' (
        author: posts:
        let path = "posts/rss/authors/${makeSlug author}.xml";
        in nameValuePair path (makeRSS {
          title = "${author} on ${config.siteTitle}";
          description = "Posts by ${author} on ${config.siteTitle}.";
          inherit path posts;
        })
      ) allAuthors)
      // optionalAttrs sectionIndexIsUseful (mapAttrs' (
        section: posts:
        let path = "posts/rss/sections/${makeSlug section}.xml";
        in nameValuePair path (makeRSS {
          title = "\"${section}\" on ${config.siteTitle}";
          description = "Posts in section \"${section}\" on ${config.siteTitle}.";
          inherit path posts;
        })
      ) allSections);

    templates = {
      all-posts = {
        function = { includeNavigation ? "true" }: ''
          ${makePostList allPosts}
          ${
            optionalString
            (includeNavigation == "true")
            "<templates-posts-navigation />"
          }
        '';
      };

      recent-posts = {
        function = { count, includeNavigation ? "true" }: ''
          ${makePostList (take (toInt count) allPosts)}
          ${
            optionalString
            (includeNavigation == "true")
            "<templates-posts-navigation />"
          }
        '';
      };

      relative-time-pill = {
        function =
          { datetime, itemprop ? null }:
          let
            # This string will be shown if JavaScript is disabled
            date = substring 0 10 datetime;
          in ''
            <time
              ${optionalString (itemprop != null) "itemprop=\"${itemprop}\""}
              datetime="${datetime}"
              title="${datetime}"
              class="relative-time"
            >on ${date}</time>
          '';

        scripts = [{
          path = "relative-time.js";
          defer = true;
          javascript = ''
            const UNITS = {
              year: 24 * 60 * 60 * 1000 * 365.25,
              month: 24 * 60 * 60 * 1000 * 365.25/12,
              day: 24 * 60 * 60 * 1000,
              hour: 60 * 60 * 1000,
              minute: 60 * 1000,
              second: 1000
            }

            const relativeFormatter = new Intl.RelativeTimeFormat(
              '${config.language}', { numeric: 'auto' }
            );
            const absoluteFormatter = new Intl.DateTimeFormat(
                '${config.language}', { dateStyle: 'medium', timeStyle: 'short' }
            );

            const elements = document.getElementsByClassName('relative-time');

            for (const element of elements) {
              const datetime = Date.parse(element.getAttribute('datetime'));

              element.setAttribute('title', absoluteFormatter.format(datetime));

              const delta = datetime - Date.now();
              for (const unit in UNITS) {
                if (Math.abs(delta) >= UNITS[unit] || unit == 'second') {
                  const number = Math.round(delta / UNITS[unit]);
                  element.innerHTML = relativeFormatter.format(number, unit);
                  break;
                }
              }
            }
          '';
        }];
      };

      author-pill =
        { author, itemprop ? "false" }:
        if authorIndexIsUseful
        then ''
          <li
            ${optionalString (itemprop == "true") "itemprop=\"author\""}
            itemscope
            itemtype="https://schema.org/Person"
          ><a
            itemprop="url"
            href="posts/authors/${makeSlug author}.html"
            title="View all posts by ${author}"
            aria-label="View all posts by ${author}"
          ><span
            itemprop="name"
          >${author}</span></a></li>
        ''
        else ''
          <li
            ${optionalString (itemprop == "true") "itemprop=\"author\""}
            itemscope
            itemtype="https://schema.org/Person"
          ><span
            itemprop="name"
          >${author}</span></li>
        '';

      section-pill =
        { section, itemprop ? "false" }:
        if sectionIndexIsUseful
        then ''
          <li ${optionalString (itemprop == "true") "itemprop=\"articleSection\""}>
          <a
            href="posts/sections/${makeSlug section}.html"
            title="View all posts about &quot;${section}&quot;"
            aria-label="View all posts about &quot;${section}&quot;"
          >${section}</a></li>
        ''
        else ''
          <li>${section}</li>
        '';

      posts-navigation =
        { rss-path ? "index.xml", rss-label ? "the RSS feed" }: ''
          <nav class="post-explore">
            Explore
            <a href="posts/index.html">all posts</a>
            ${optionalString pillsIndexIsUseful ''
              or the <a href="posts/pills.html">index</a>
            ''}
            &middot;
            Subscribe to
            <a href="posts/rss/${rss-path}">${rss-label}</a>
          </nav>
        '';
    };
  };
}
