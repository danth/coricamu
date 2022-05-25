{ pkgsLib, ... }@args:
typeArgs:

with pkgsLib.types;

submoduleWith {
  modules = [ (import ./modules/default.nix typeArgs) ];
  specialArgs = args;
  shorthandOnlyDefinesConfig = true;
}
