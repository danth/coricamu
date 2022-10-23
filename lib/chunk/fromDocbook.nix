{ pandoc, runCommand, writeText }:

{
  type,
  string ? null,
  file ? writeText "chunk.xml" string
}:

{
  inherit type;

  file = runCommand "${builtins.baseNameOf file}.html" {
    preferLocalBuild = true;
    allowSubstitutes = false;
  } ''
    ${pandoc}/bin/pandoc -f docbook -t html <${file} >$out
  '';
}
