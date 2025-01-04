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
  mkBaseProject =
    projectModule:
    (lib.evalModules {
      modules = [
        self.modules.flake.project
        projectModule
        { relativePaths.toRoot = lib.mkDefault "./."; }
      ];
    }).config;
in
risingTideBootstrapLib
// {
  inherit filterAttrsRecursive mkBaseProject;
  mkProject =
    projectModule:
    mkBaseProject {
      imports = [ projectModule ];
      config.defaultSettings = self.modules.flake.risingTideConventions;
    };
  sanitizeBashIdentifier = lib.strings.sanitizeDerivationName;
  types = {
    callPackageFunction = (types.addCheck types.unspecified builtins.isFunction) // {
      name = "callPackageFunction";
      description = "A function that can be called by callPackage and returns a package";
    };
    subpath = types.str // {
      name = "subpath";
      description = "A relative path";
      merge = loc: defs: lib.path.subpath.normalise (lib.mergeEqualOption loc defs);
    };
    overlay = lib.mkOptionType {
      name = "overlay";
      description = "A package overlay";
      descriptionClass = "noun";
      merge =
        _loc: defs:
        let
          list = lib.options.getValues defs;
        in
        lib.composeManyExtensions list;
      emptyValue = {
        value = { };
      };
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
