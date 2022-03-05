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
          ${concatMapStringsSep "\n" (page: page.sitemap.xml) config.pages}
        </urlset>
      '';

      # html-tidy is 2-in-1:
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
