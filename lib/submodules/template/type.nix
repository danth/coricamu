{ pkgsLib, ... }@args:

with pkgsLib.types;

submoduleWith {
  modules = [
    ./modules/default.nix
    (import ../image/option.nix { isToplevel = false; })
    (import ../style/option.nix { isToplevel = false; })
    (import ../script/option.nix { isToplevel = false; })
  ];
  specialArgs = args;
  shorthandOnlyDefinesConfig = true;
}
