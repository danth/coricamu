{ pkgs, ... }:

{
  templates.mermaid = {
    function =
      { contents }:
      "<pre class=\"mermaid\">${contents}</pre>";

    scripts = [{
      path = "mermaid@9.2.2.js";
      javascriptFile = pkgs.fetchurl {
        url = "https://cdn.jsdelivr.net/npm/mermaid@9.2.2/dist/mermaid.js";
        sha256 = "iY9SZy4mS0SsM4CmSTRfL9KOQnR+a9+O+P1+aTtIuao=";
      };
      defer = true;
    }];
  };
}
