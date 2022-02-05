{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

let
  posts = sort (a: b: a.datetime > b.datetime) config.posts;

  makePostList = posts: ''
    <ol style="list-style-type: none">
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
    pages = makePostPages posts // {
      postsIndex = mkIf (length config.posts > 0) {
        path = "posts/index.html";
        title = "All posts";
        body.html = config.templates.all-posts {};
      };
    };

    templates = {
      all-posts = { }: makePostList posts;
      recent-posts = { count }: makePostList (take (toInt count) posts);
    };
  };
}
