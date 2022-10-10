{ pkgs, ... }:

{
  templates.mermaid = {
    function =
      { contents }:
      "<pre class=\"mermaid\">${contents}</pre>";

    scripts = [{
      path = "mermaid@9.1.7.js";
      javascriptFile = pkgs.fetchurl {
        url = "https://cdn.jsdelivr.net/npm/mermaid@9.1.7/dist/mermaid.js";
        sha256 = "5ZEQFGiF7DmrBf8P7c5EcsOUldgHNKU0hTzGiEhjGc4=";
      };
      defer = true;
    }];
  };
}
