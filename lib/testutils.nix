{ lib, risingTideLib, ... }:
let
  inherit (risingTideLib) filterAttrsByPathRecursive;
in
rec {
  filterExprToExpected =
    {
      expected,
      expr,
    }:
    {
      inherit expected;
      unfilteredExpr = expr;
      expr = filterAttrsByPathRecursive (path: _value: lib.hasAttrByPath path expected) expr;
    };
  mkExpectRenderedConfig =
    {
      modules,
      filter ? true,
    }:
    module: expected:
    let
      expr =
        (lib.evalModules {
          modules = modules ++ [ module ];
        }).config;
      result = { inherit expr expected; };
    in
    if filter == true then filterExprToExpected result else result;
}
