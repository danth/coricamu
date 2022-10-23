{ lib, multimarkdown }:

{
  type,
  string ? null,
  file ? null
}:

{
  inherit type;

  buildCommand = toString [
    "${multimarkdown}/bin/multimarkdown"
    "--snippet"
    "--notransclude"
    "--to=html"
    ">> $out"
    (if file != null
     then "< ${file}"
     else "<<< ${lib.escapeShellArg string}")
  ];
}
