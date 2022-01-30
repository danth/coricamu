{ pkgsLib, ... }:

with pkgsLib;
with types;

{
  imports = [
    ./files.nix
    ./pages.nix
    ./styles.nix
  ];

  options.package = mkOption {
    description = "Derivation containing the web root.";
    internal = true;
    type = package;
  };
}
