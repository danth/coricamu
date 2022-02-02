{ pkgsLib, ... }@args:

with pkgsLib;
with pkgsLib.types;

{
  types = {
    content = templates: submoduleWith {
      modules = [ ../modules/content/default.nix ];
      specialArgs = {
        inherit (args) coricamuLib pkgsLib pkgs;
        inherit templates;
      };
      shorthandOnlyDefinesConfig = true;
    };

    post = websiteConfig: submoduleWith {
      modules = [ ../modules/post/default.nix ];
      specialArgs = {
        inherit (args) coricamuLib pkgsLib pkgs;
        inherit websiteConfig;
      };
      shorthandOnlyDefinesConfig = true;
    };

    page = websiteConfig: submoduleWith {
      modules = [ ../modules/page/default.nix ];
      specialArgs = {
        inherit (args) coricamuLib pkgsLib pkgs;
        inherit websiteConfig;
      };
      shorthandOnlyDefinesConfig = true;
    };

    template = functionTo lines;
  };
}
