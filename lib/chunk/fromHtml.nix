{ lib }:

{
  type,
  string ? null,
  file ? null,
  auxiliary ? {}
}:

{
  inherit type auxiliary;

  buildCommand =
    if file != null
    then "cat ${file} >> $out"
    else "echo ${lib.escapeShellArg string} >> $out";
}
