{ coricamu, writeText }:

{
  name,
  string ? null,
  file ? writeText "script.js" string,
  auxiliaryFiles ? {}
}:

let
  scriptUrl = "/scripts/${name}.js";

in coricamu.chunk.fromHtml {
  type = "head";

  string = ''
    <script src="${scriptUrl}" />
  '';

  auxiliaryFiles = auxiliaryFiles // {
    ${scriptUrl} = file;
  };
}
