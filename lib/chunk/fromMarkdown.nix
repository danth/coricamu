{ multimarkdown, runCommand, writeText }:

{
  type,
  string ? null,
  file ? writeText "chunk.md" string
}:

{
  inherit type;

  file = runCommand "${builtins.baseNameOf file}.html" {
    preferLocalBuild = true;
    allowSubstitutes = false;
  } ''
    ${multimarkdown}/bin/multimarkdown \
      --snippet \
      --notransclude \
      --to=html \
      --output=$out \
      ${file}
  '';
}
