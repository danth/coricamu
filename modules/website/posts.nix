{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options.posts = mkOption {
    description = "List of all posts.";
    type = listOf (post config);
  };

  config.pages =
    (listToAttrs (map
      (post: nameValuePair post.slug post.page)
      config.posts))
    // {
      postsIndex = {
        path = "posts/index.html";
        title = "All posts";
        body = ''
          <ol style="list-style-type: none">
            ${
              concatMapStringsSep "\n"
              (post: "<li>${post.indexEntry}</li>")
              config.posts
            }
          </ol>
        '';
      };
    };
}
