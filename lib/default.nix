{
  lib,
  risingTideBootstrapLib,
  self,
  ...
}:
let
  inherit (lib) types;
  filterAttrsRecursive =
    pred:
    let
      recurse =
        prefix: set:
        builtins.listToAttrs (
          builtins.concatMap (
            name:
            let
              v = set.${name};
            in
            if pred (prefix ++ [ name ]) v then
              [
                (lib.nameValuePair name (if builtins.isAttrs v then recurse (prefix ++ [ name ]) v else v))
              ]
            else
              [ ]
          ) (builtins.attrNames set)
        );
    in
    recurse [ ];
in
risingTideBootstrapLib
// {
  inherit filterAttrsRecursive;
  mkProject =
    projectModule:
    (lib.evalModules {
      modules = [
        self.modules.flake.project
        projectModule
        { relativePaths.toRoot = lib.mkDefault "./."; }
      ];
    }).config;
  sanitizeBashIdentifier = lib.strings.sanitizeDerivationName;
  types = {
    subpath = types.str // {
      name = "subpath";
      description = "A relative path";
      merge = loc: defs: lib.path.subpath.normalise (lib.mergeEqualOption loc defs);
    };
  };
  tests =
    let
      filterExprToExpected =
        {
          expected,
          expr,
        }:
        {
          inherit expected;
          unfilteredExpr = expr;
          expr = filterAttrsRecursive (path: _value: lib.hasAttrByPath path expected) expr;
        };
    in
    {
      inherit filterExprToExpected;
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
    };
}
