# rising-tide flake context
{ lib, ... }:
let
  toDerivation =
    path:
    let
      path' = builtins.toString path;
      res = {
        type = "derivation";
        name = lib.sanitizeDerivationName (builtins.substring 33 (-1) (baseNameOf path'));
        outPath = path';
        outputs = [ "out" ];
        out = res;
        outputName = "out";
      };
    in
    res;
in
{
  noop =
    { data, ... }:
    if lib.isDerivation data then
      data
    else
      assert lib.assertMsg (builtins.isPath data)
        "risingTideLib.nixagoEngines.noop: The data argument is of type ${builtins.typeOf data} but should either be a derivation or a path";
      toDerivation data;
}
