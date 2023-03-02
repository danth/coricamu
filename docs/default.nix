{ coricamuLib, config, ... }:

with coricamuLib;

rec {
  baseUrl = "https://danth.github.io/coricamu/";
  siteTitle = "Coricamu";
  language = "en-gb";

  header = makeProjectHeader {
    title = siteTitle;
    inherit (config) pages;
    repository = "https://github.com/danth/coricamu";
  };

  pages = makeProjectPages ../. ++ [
    {
      path = "options.html";
      title = "Options";
      body.docbook = makeOptionsDocBook {
        inherit (evalSite { modules = []; }) options;
      };
    }
  ];
}
