{ coricamu, runCommand }:

with coricamu;

makeWebsite {
  baseUrl = "https://danth.github.io/coricamu/";

  commonChunks = [
    (chunk.fromHtml {
      type = "header";
      string = "<h1>Coricamu</h1>";
    })
    (chunk.includeStyle {
      name = "docs";
      string = ''
        body {
          margin: 3em auto;
          max-width: 800px;
          font-family: sans-serif;
        }
      '';
    })
  ];

  files = [
    (makePage {
      name = "index";
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
    })
  ];
}
