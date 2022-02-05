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

    language = mkOption {
      description = "Language the website is written in.";
      example = "en-us";
      type =
        let pattern = "[a-zA-Z]{2}(-[a-zA-Z]{2})?";
        in mkOptionType {
          name = "Language";
          description = "BCP 47 Language-Region code";
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
