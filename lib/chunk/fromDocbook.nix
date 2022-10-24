{ lib, pandoc }:

{
  type,
  string ? null,
  file ? null,
  auxiliaryFiles ? {}
}:

{
  inherit type auxiliaryFiles;

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
