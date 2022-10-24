{ coricamu, runCommand }:

with coricamu;

makeWebsite {
  baseUrl = "https://danth.github.io/coricamu/";

  files = [
    (makePage {
      title = "Coricamu";
      chunks = [
        (chunk.fromHtml {
          type = "header";
          string = "<h1>Coricamu</h1>";
        })
        (chunk.fromMarkdown {
          type = "main";
          file = runCommand "index.md" {} ''
            # Remove the title line
            tail -n+2 ${../README.md} >$out
          '';
        })
      ];
    })
  ];
}
