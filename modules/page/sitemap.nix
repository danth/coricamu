{ pkgsLib, config, websiteConfig, ... }:

with pkgsLib;
with types;

{
  options.sitemap = {
    # https://www.sitemaps.org/protocol.html

    lastModified = mkOption {
      description = "Date this page was last modified.";
      example = "2022-01-30";
      type = nullOr (strMatching "[0-9]{4}-[0-9]{2}-[0-9]{2}");
      default = null;
    };

    changeFrequency = mkOption {
      description = ''
        How often this page is likely to be edited.

        This value may influence how often search engines will crawl your page.
      '';
      # "always" is also a vaild value, however it means the page is generated
      # dynamically for every request, which is not possible with Coricamu
      type = nullOr (enum [ "hourly" "daily" "weekly" "monthly" "yearly" "never" ]);
      default = null;
    };

    priority = mkOption {
      description = ''
        Priority of this page compared to other pages on your site.

        This value may influence the order in which search engines index your
        pages (so that higher priority pages are checked sooner / more often).
        It is unlikely to affect your position in search results.

        This is a decimal number between 0 and 1, stored as a string.
      '';
      example = "1.0";
      type = strMatching "(0\\.[0-9]+|1\\.0+)";
      default = "0.5";
    };

    xml = mkOption {
      description = "Raw XML sitemap entry.";
      internal = true;
      type = lines;
    };
  };

  config.sitemap.xml = ''
    <url>
      <loc>${websiteConfig.baseUrl}${config.path}</loc>
      ${
        if !(isNull config.sitemap.lastModified)
        then "<lastmod>${config.sitemap.lastModified}</lastmod>"
        else ""
      }
      ${
        if !(isNull config.sitemap.changeFrequency)
        then "<changefreq>${config.sitemap.changeFrequency}</changefreq>"
        else ""
      }
      <priority>${config.sitemap.priority}</priority>
    </url>
  '';
}