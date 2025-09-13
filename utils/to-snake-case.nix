{ lib }:
let
  isUpper = c: c == lib.toUpper c && c != lib.toLower c;
in
input:
lib.toLower (
  lib.concatMapStringsSep "" (char: if isUpper char then "_" + lib.toLower char else char) (
    lib.strings.stringToCharacters input
  )
)
