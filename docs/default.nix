{ coricamu, runCommand }:

with coricamu;

makeWebsite {
  baseUrl = "https://danth.github.io/coricamu/";
  title = "Coricamu";

  files."index.html" = makePage {
    title = "Coricamu";
    chunks = [
      (chunk.fromMarkdown {
        type = "main";
        file = runCommand "index.md" {} ''
          # Remove the title line
          tail -n+2 ${../README.md} >$out
        '';
      })
    ];
  };
}
