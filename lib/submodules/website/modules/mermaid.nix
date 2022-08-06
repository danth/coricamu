{ pkgs, ... }:

{
  templates.mermaid = {
    function =
      { contents }:
      "<pre class=\"mermaid\">${contents}</pre>";

    scripts = [{
      path = "mermaid@8.14.0.js";
      javascriptFile = pkgs.fetchurl {
        url = "https://cdn.jsdelivr.net/npm/mermaid@8.14.0/dist/mermaid.js";
        sha256 = "HgkOi3/ypnDigo/pp/J1Bxvf5mY4hqvDW+YrxdqfMIM=";
      };
      defer = true;
    }];
  };
}
