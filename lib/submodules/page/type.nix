{ pkgsLib, ... }@args:

with pkgsLib.types;

websiteConfig:

submoduleWith {
  modules = [
    ./modules/default.nix
    ./modules/fontawesome.nix
    ./modules/mermaid.nix
    ./modules/sitemap.nix
    ../image/option.nix
    (import ../style/option.nix {
      insertDefault = false;
    })
  ];
  specialArgs = args // { inherit websiteConfig; };
  shorthandOnlyDefinesConfig = true;
}
