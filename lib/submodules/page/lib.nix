{ pkgsLib, ... }:

with pkgsLib;

{
  pageContains = infix: { config, websiteConfig, ... }:
    hasInfix infix config.body.output ||
    hasInfix infix websiteConfig.header.output ||
    hasInfix infix websiteConfig.footer.output;
}
