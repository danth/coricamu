{ writeText }:

{
  type,
  string ? null,
  file ? writeText "chunk.html" string
}:

{
  inherit type file;
}
