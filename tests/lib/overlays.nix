# rising-tide flake context
{ lib, risingTideLib, ... }:
let
  inherit (risingTideLib.tests) filterExprToExpected;
  simpleScope = lib.makeScope (extra: lib.callPackageWith extra) (_self: {
    a = 1;
    b = 2;
  });
  scopeWithNestedScope = simpleScope.overrideScope (
    final: _prev: {
      nested = lib.makeScope final.newScope (_self: {
        inner = 42;
      });
    }
  );
in
{
  mkOverlay = {
    "test simpleScope" = filterExprToExpected {
      expr = simpleScope;
      expected = {
        a = 1;
        b = 2;
      };
    };

    "test scopeWithNestedScope" = filterExprToExpected {
      expr = scopeWithNestedScope;
      expected = {
        a = 1;
        b = 2;
        nested.inner = 42;
      };
    };

    "test mkOverlay at one level" = filterExprToExpected {
      expr = simpleScope.overrideScope (risingTideLib.mkOverlay [ "foo" ] ({ }: 7));
      expected = {
        a = 1;
        b = 2;
        foo = 7;
      };
    };

    "test mkOverlay at two levels" = filterExprToExpected {
      expr = simpleScope.overrideScope (risingTideLib.mkOverlay [ "foo" "bar" ] ({ }: 7));
      expected = {
        a = 1;
        b = 2;
        foo.bar = 7;
      };
    };

    "test mkOverlay applies to a nested scope" = filterExprToExpected {
      expr = simpleScope.overrideScope (risingTideLib.mkOverlay [ "nested" "baz" ] ({ }: 7));
      expected = {
        a = 1;
        b = 2;
        nested = {
          inner = 42;
          baz = 7;
        };
      };
    };

  };
}
