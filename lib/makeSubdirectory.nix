{ coricamu, lib }:

with lib;

{
  name,
  files ? [],
  makeManifests ? (files: {}),
  isRoot ? false
}:

let
  files' = removeAttrs (coricamu.mergeFiles files) ["override" "overrideDerivation"];

  isAtRoot = path: hasPrefix "/" path;
  filesAtRoot = filterAttrs (path: _: isAtRoot path) files';
  filesInSubdirectory = filterAttrs (path: _: !(isAtRoot path)) files';

  reparent =
    if isRoot
    then id
    else mapAttrs' (path: file: nameValuePair "${name}/${path}" file);

  manifests =
    if isRoot
    then makeManifests (filesAtRoot // filesInSubdirectory)
    else makeManifests filesInSubdirectory;

  subdirectory = reparent (filesInSubdirectory // manifests);

in filesAtRoot // subdirectory
