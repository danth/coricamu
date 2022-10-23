{ lib, pandoc }:

{
  type,
  string ? null,
  file ? null,
  auxiliary ? {}
}:

{
  inherit type auxiliary;

  buildCommand = toString [
    "${pandoc}/bin/pandoc"
    "-f docbook"
    "-t html"
    ">> $out"
    (if file != null
     then "< ${file}"
     else "<<< ${lib.escapeShellArg string}")
  ];
}
