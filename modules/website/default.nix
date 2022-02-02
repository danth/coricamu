{ pkgsLib, ... }:

with pkgsLib;
with types;

{
  imports = [
    ./files.nix
    ./pages.nix
    ./posts.nix
    ./sitemap.nix
    ./styles.nix
  ];

  options = {
    baseUrl = mkOption {
      description = "URL of the root of your website.";
      example = "https://example.com/";
      type =
        let pattern =
          "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?/$";
        in mkOptionType {
          name = "URL";
          description = "URL ending with /";
          check = x: str.check x && builtins.match pattern x != null;
          inherit (str) merge;
        };
    };

    package = mkOption {
      description = "Derivation containing the web root.";
      internal = true;
      type = package;
    };
  };
}
