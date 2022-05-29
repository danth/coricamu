{ pkgsLib, ... }@args:

with pkgsLib.types;

websiteConfig:

submoduleWith {
  modules = [
    ./modules/default.nix
    ./modules/sitemap.nix
      (import ../image/option.nix { isToplevel = true; })
      (import ../style/option.nix { isToplevel = true; })
  ];
  specialArgs = args // { inherit websiteConfig; };
  shorthandOnlyDefinesConfig = true;
}
