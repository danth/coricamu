{ pkgsLib, ... }@args:

with pkgsLib.types;

websiteConfig:

submoduleWith {
  modules = [
    ./modules/default.nix
    ./modules/sitemap.nix
      (import ../image/option.nix { isToplevel = false; })
      (import ../style/option.nix { isToplevel = false; })
      (import ../script/option.nix { isToplevel = false; })
  ];
  specialArgs = args // { inherit websiteConfig; };
  shorthandOnlyDefinesConfig = true;
}
