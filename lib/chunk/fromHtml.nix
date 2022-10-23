{ lib }:

{
  type,
  string ? null,
  file ? null
}:

{
  inherit type;

  buildCommand =
    if file != null
    then "cat ${file} >> $out"
    else "echo ${lib.escapeShellArg string} >> $out";
}
