{ lib }:

{
  type,
  string ? null,
  file ? null,
  auxiliaryFiles ? {}
}:

{
  inherit type auxiliaryFiles;

  buildCommand =
    if file != null
    then "cat ${file} >> $out"
    else "echo ${lib.escapeShellArg string} >> $out";
}
