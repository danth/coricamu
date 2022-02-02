{ coricamuLib, pkgsLib, pkgs, config, ... }:

with pkgsLib;
with pkgsLib.types;
with coricamuLib.types;

{
  options.posts = mkOption {
    description = "List of all posts.";
    type = listOf (post config);
    default = [];
  };

  config = mkIf (length config.posts > 0) {
    pages =
      (listToAttrs (map
        (post: nameValuePair post.slug post.page)
        config.posts))
      // {
        postsIndex = {
          path = "posts/index.html";
          title = "All posts";
          body.html = ''
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
  };
}
