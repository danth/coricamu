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

    # Suggest that search engines look at this page last
    # (although this is not honoured by Google}
    sitemap.priority = "0.0";
  };

  makePostList = posts: ''
    <ol class="post-list">
      ${concatMapStringsSep "\n" (post: "<li>${post.indexEntry}</li>") posts}
    </ol>
  '';

  makePostPages = posts:
    listToAttrs (map (post: nameValuePair post.slug post.page) posts);

in {
  options.posts = mkOption {
    description = "List of all posts.";
    type = listOf (post config);
    default = [];
  };

  config = {
    pages = mkMerge [
      # Individual posts
      (makePostPages allPosts)

      # All posts chronologically
      (mkIf (length allPosts > 0) {
        postsIndex = indexConfig // rec {
          path = "posts/index.html";
          title = "All posts";
          body.html = ''
            <h1>${title}</h1>
            ${config.templates.posts-navigation {}}

            ${makePostList allPosts}
          '';
        };
      })

      # Individual authors
      (mkIf authorIndexIsUseful (mapAttrs' (
        author: posts:
        nameValuePair
        "author-${author}"
        (indexConfig // rec {
          path = "posts/authors/${makeSlug author}.html";
          title = "Posts by ${author}";
          body.html = ''
            <h1>${title}</h1>
            ${config.templates.posts-navigation {}}

            ${makePostList posts}
          '';
        })
      ) allAuthors))

      # Individual keywords
      (mkIf keywordIndexIsUseful (mapAttrs' (
        keyword: posts:
        nameValuePair
        "keyword-${keyword}"
        (indexConfig // {
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
        })
      ) allKeywords))

      # All posts by author / keyword
      (mkIf pillsIndexIsUseful {
        postsByPill = indexConfig // rec {
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
        };
      })
    ];

    templates = {
      all-posts = { }: makePostList allPosts;

      recent-posts = { count }: makePostList (take (toInt count) allPosts);

      author-pill =
        { author, itemprop ? false }:
        if authorIndexIsUseful
        then ''
          <li><a
            ${optionalString itemprop "itemprop=\"author\""}
            href="/posts/authors/${makeSlug author}.html"
            title="View all posts by ${author}"
            aria-label="View all posts by ${author}"
          >${author}</a></li>
        ''
        else ''
          <li>${author}</li>
        '';

      keyword-pill =
        { keyword }:
        if keywordIndexIsUseful
        then ''
          <li><a
            href="/posts/keywords/${makeSlug keyword}.html"
            title="View all posts about ${keyword}"
            aria-label="View all posts about ${keyword}"
          >${keyword}</a></li>
        ''
        else ''
          <li>${keyword}</li>
        '';

      posts-navigation = { }: ''
        <nav class="post-explore">
          Explore
          <a href="/${config.pages.postsIndex.path}">all posts</a>
          ${optionalString pillsIndexIsUseful ''
            or the
            <a href="/${config.pages.postsByPill.path}">index</a>
          ''}
        </nav>
      '';
    };
  };
}
