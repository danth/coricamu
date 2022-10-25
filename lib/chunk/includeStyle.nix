{ coricamu, writeText }:

{
  name,
  string ? null,
  file ? writeText "style.css" string,
  auxiliaryFiles ? {}
}:

let
  styleUrl = "/styles/${name}.css";

in coricamu.chunk.fromHtml {
  type = "head";

  string = ''
    <link rel="stylesheet" href="${styleUrl}" />
  '';

  auxiliaryFiles = auxiliaryFiles // {
    ${styleUrl} = file;
  };
}
