{ lib, converter }:
let
  convertAttributes =
    attrs:
    lib.mapAttrs' (
      n: v: lib.nameValuePair (converter n) (if lib.isAttrs v then convertAttributes v else v)
    ) attrs;
in
convertAttributes
