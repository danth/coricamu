{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;
with coricamuLib.types;

let
  allPosts = sort (a: b: a.datetime > b.datetime) config.posts;

  # { keyword: [post]; }
  keywordPair = post: keyword: nameValuePair keyword [post];
  # { keyword_one: [post]; keyword_two: [post]; }
  postKeywords = post: listToAttrs (map (keywordPair post) post.keywords);
  # { keyword_one: [post_one post_two]; keyword_two: [post_one post_three]; }
  allKeywords = foldAttrs concat [] (map postKeywords allPosts);

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
      # Individual post
      (makePostPages allPosts)

      # All posts
      (mkIf (length allPosts > 0) {
        postsIndex = rec {
          path = "posts/index.html";
          title = "All posts";

          # There is no point having this index appear on a search engine,
          # and it's not needed by the engine itself to discover other
          # pages because sitemap.xml exists
          meta.robots = "noindex";

          body.html = ''
            <h1>${title}</h1>
            ${config.templates.posts-navigation {}}

            ${makePostList allPosts}
          '';
        };
      })

      # Individual keyword
      (mapAttrs' (
        keyword: posts:
        nameValuePair "keyword-${keyword}" {
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

      # All keywords
      (mkIf (length (attrNames allKeywords) > 0) {
        keywordsIndex = rec {
          path = "posts/keywords/index.html";
          title = "Keyword index";

          # There is no point having this index appear on a search engine,
          # and it's not needed by the engine itself to discover other
          # pages because sitemap.xml exists
          meta.robots = "noindex";

          body.html = ''
            <h1>${title}</h1>
            ${config.templates.posts-navigation {}}

            <ul class="keywords">
              ${concatStringsSep "\n" (mapAttrsToList (keyword: posts: ''
                <li><a
                  href="/posts/keywords/${makeSlug keyword}.html"
                  title="View all posts about ${keyword}"
                  aria-label="View all posts about ${keyword}"
                >${keyword}</a></li>
              '') allKeywords)}
            </ul>
          '';
        };
      })
    ];

    templates = {
      all-posts = { }: makePostList allPosts;

      recent-posts = { count }: makePostList (take (toInt count) allPosts);

      posts-navigation = { }: ''
        <nav class="post-explore">
          Explore
          <a href="/${config.pages.postsIndex.path}">all posts</a>
          ${optionalString (length (attrNames allKeywords) > 0) ''
            or the
            <a href="/${config.pages.keywordsIndex.path}">index</a>
          ''}
        </nav>
      '';
    };
  };
}
