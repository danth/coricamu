{ pkgsLib, ... }@args:

with pkgsLib.types;

submoduleWith {
  modules = [ ./modules/default.nix ];
  specialArgs = args;
  shorthandOnlyDefinesConfig = true;
}
