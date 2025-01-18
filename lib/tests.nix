# rising-tide flake context
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
      specialArgs ? { },
      filter ? true,
    }:
    module: expected:
    let
      expr =
        (lib.evalModules {
          inherit specialArgs;
          modules = modules ++ [ module ];
        }).config;
      result = { inherit expr expected; };
    in
    if filter == true then filterExprToExpected result else result;
}
