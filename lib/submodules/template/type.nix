{ pkgsLib, ... }@args:

with pkgsLib.types;

submoduleWith {
  modules = [
    ./modules/default.nix
    ../image/option.nix
    (import ../style/option.nix {
      insertDefault = false;
    })
  ];
  specialArgs = args;
  shorthandOnlyDefinesConfig = true;
}
