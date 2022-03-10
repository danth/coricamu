{ coricamuLib, pkgsLib, pkgs, config, ... }:

with coricamuLib;
with pkgsLib;
with types;

{
  files = {
    "sitemap.xml" = writeMinified {
      name = "sitemap.xml";

      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="https://www.sitemaps.org/schemas/sitemap/0.9">
          ${concatMapStringsSep "\n" (page: page.sitemap.xml) config.pages}
        </urlset>
      '';

      checkPhase = ''
        if [ "$(stat -c%s $target)" -gt 52428800 ]; then
          echo "Sitemap is larger than the maximum 50MB"
          exit 1
        fi

        ${
          if length config.pages > 50000
          then ''
            echo "Sitemap contains more than the maximum 50,000 pages"
            exit 1
          ''
          else ""
        }
      '';
    };

    "robots.txt" = mkDefault (pkgs.writeTextFile {
      name = "robots.txt";
      text = "sitemap: ${config.baseUrl}sitemap.xml";
    });
  };
}
