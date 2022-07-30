{ pkgs, coricamuLib, ... }:

{
  baseUrl = "https://danth.github.io/coricamu/";
  siteTitle = "Coricamu";
  language = "en-gb";

  header.html = ''
    <h1>Coricamu</h1>
    <nav>
      <a href="">Home</a>
      <a href="options.html">Options list</a>
      <a href="https://github.com/danth/coricamu">GitHub repository</a>
    </nav>
  '';

  pages = [
    {
      path = "index.html";
      title = "Coricamu";
      body.markdownFile = pkgs.runCommand "index.md" {} ''
        # Remove the title line
        tail -n+2 ${../README.md} >$out
      '';
    }
    {
      path = "options.html";
      title = "NixOS Options";
      body.docbook = coricamuLib.makeOptionsDocBook {
        inherit (coricamuLib.evalSite { modules = []; }) options;
      };
    }
  ];
}
