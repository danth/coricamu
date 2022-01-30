{ coricamuLib, pkgsLib, ... }@args:

{
  evalSite =
    { modules, specialArgs ? {} }:
    pkgsLib.evalModules {
      modules = [ ../modules/website ] ++ modules;
      specialArgs = {
        inherit (args) coricamuLib pkgsLib pkgs;
      } // specialArgs;
    };

  buildSite = args: (coricamuLib.evalSite args).config.package;
}
