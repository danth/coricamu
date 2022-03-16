{ pkgsLib, ... }@args:

with pkgsLib.types;

websiteConfig:

submoduleWith {
  modules = [ ./modules/default.nix ];
  specialArgs = args // { inherit websiteConfig; };
  shorthandOnlyDefinesConfig = true;
}
