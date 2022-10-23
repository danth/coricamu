{ coricamu, writeText }:

{
  name,
  string ? null,
  file ? writeText "script.js" string,
  auxiliary ? {}
}:

let
  scriptUrl = "/scripts/${name}.js";

in coricamu.chunk.fromHtml {
  type = "head";

  string = ''
    <script src="${scriptUrl}" />
  '';

  auxiliary = auxiliary // {
    ${scriptUrl} = file;
  };
}
