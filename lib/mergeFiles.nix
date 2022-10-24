{ lib }:

with lib;

let
  mergeIfEqual = path: files:
    if length (unique files) == 1
    then elemAt files 0
    else throw "conflict between ${concatStringsSep "," files}";

in zipAttrsWith mergeIfEqual
