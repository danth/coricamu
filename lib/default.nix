{ callPackage }:

{
  chunk = {
    fromMarkdown = callPackage ./chunk/fromMarkdown.nix {};
  };
  makePage = callPackage ./makePage.nix {};
  makeWebsite = callPackage ./makeWebsite.nix {};
  string = {
    makeSlug = callPackage ./string/makeSlug.nix {};
  };
}
