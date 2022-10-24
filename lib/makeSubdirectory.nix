{ coricamu, lib }:

with lib;

{
  name,
  files ? [],
  commonChunks ? [],
  makeManifests ? (files: {}),
  isRoot ? false
}:

let
  files' = removeAttrs (coricamu.mergeFiles files) ["override" "overrideDerivation"];

  absolutePaths = filterAttrs (path: _: hasPrefix "/" path) files';
  relativePaths = filterAttrs (path: _: !(hasPrefix "/" path)) files';

  addCommonChunks = file:
    if isAttrs file && file.type == "page"
    then file.addChunks commonChunks
    else file;

  relativePaths' =
    let newFiles = mapAttrsToList (_: addCommonChunks) relativePaths;
    # `addChunks` could introduce new auxiliary files which need to be merged in
    in coricamu.mergeFiles newFiles;

  reparent =
    if isRoot
    then id
    else mapAttrs' (path: file: nameValuePair "${name}/${path}" file);

  manifests =
    if isRoot
    then makeManifests (absolutePaths // relativePaths')
    else makeManifests relativePaths';

  subdirectory = reparent (relativePaths' // manifests);

in absolutePaths // subdirectory
