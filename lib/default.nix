{ lib, callPackage }:

let
  importFunction =
    file:
    let function = callPackage file {};
    in lib.makeOverridable function;

in {
  chunk = {
    fromMarkdown = importFunction ./chunk/fromMarkdown.nix;
  };
  makePage = importFunction ./makePage.nix;
  makeWebsite = importFunction ./makeWebsite.nix;
  string = {
    makeSlug = importFunction ./string/makeSlug.nix;
  };
}
