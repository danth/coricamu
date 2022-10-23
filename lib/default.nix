{ lib, callPackage }:

let
  importFunction =
    file:
    let function = callPackage file {};
    in lib.makeOverridable function;

in {
  chunk = {
    fromDocbook = importFunction ./chunk/fromDocbook.nix;
    fromHtml = importFunction ./chunk/fromHtml.nix;
    fromMarkdown = importFunction ./chunk/fromMarkdown.nix;
    includeScript = importFunction ./chunk/includeScript.nix;
  };
  makePage = importFunction ./makePage.nix;
  makeWebsite = importFunction ./makeWebsite.nix;
  string = {
    makeSlug = importFunction ./string/makeSlug.nix;
  };
}
