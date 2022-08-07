{ pkgs, ... }:

{
  templates.mermaid = {
    function =
      { contents }:
      "<pre class=\"mermaid\">${contents}</pre>";

    scripts = [{
      path = "mermaid@9.1.4.js";
      javascriptFile = pkgs.fetchurl {
        url = "https://cdn.jsdelivr.net/npm/mermaid@9.1.4/dist/mermaid.js";
        sha256 = "bq7V70Dsp2rvYbu/KJA//TPzdrtRTdwl06OWqJiOglg=";
      };
      defer = true;
    }];
  };
}
