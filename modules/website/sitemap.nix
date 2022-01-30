{ coricamuLib, pkgsLib, pkgs, config, ... }:

with coricamuLib;
with pkgsLib;
with types;

{
  files = {
    "sitemap.xml" = pkgs.writeTextFile {
      name = "sitemap.xml";

      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="https://www.sitemaps.org/schemas/sitemap/0.9">
          ${mapAttrsToString (name: page: page.sitemap.xml) config.pages}
        </urlset>
      '';

      # 2-in-1:
      # - Raises an error if the XML is invalid
      # - Cleans up erratic indentation caused by splices
      checkPhase = ''
        ${pkgs.html-tidy}/bin/tidy \
          --input-xml yes \
          --output-xml yes \
          --indent auto \
          --wrap 100 \
          --quiet yes \
          -modify $target
      '';
    };

    "robots.txt" = mkDefault (pkgs.writeTextFile {
      name = "robots.txt";
      text = "sitemap: ${config.baseUrl}sitemap.xml";
    });
  };
}
