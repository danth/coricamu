{ pkgsLib, ... }@args:

with pkgsLib.types;

websiteConfig:

submoduleWith {
  modules = [
    ./modules/default.nix
    ./modules/mermaid.nix
    ./modules/sitemap.nix
  ];
  specialArgs = args // { inherit websiteConfig; };
  shorthandOnlyDefinesConfig = true;
}
