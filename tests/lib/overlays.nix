# rising-tide flake context
{ lib, risingTideLib, ... }:
let
  inherit (risingTideLib.tests) filterExprToExpected;
  simpleScope = lib.makeScope (extra: lib.callPackageWith extra) (_self: {
    a = 1;
    b = 2;
    c.d = 3;
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
        c.d = 3;
      };
    };

    "test scopeWithNestedScope" = filterExprToExpected {
      expr = scopeWithNestedScope;
      expected = {
        a = 1;
        b = 2;
        c.d = 3;
        nested.inner = 42;
      };
    };

    "test mkOverlay at one level" = filterExprToExpected {
      expr = simpleScope.overrideScope (risingTideLib.mkOverlay [ "foo" ] ({ a, b }: a + b));
      expected = {
        a = 1;
        b = 2;
        c.d = 3;
        foo = 3;
      };
    };

    "test mkOverlay at two levels" = filterExprToExpected {
      expr = simpleScope.overrideScope (risingTideLib.mkOverlay [ "foo" "bar" ] ({ a, b }: a + b));
      expected = {
        a = 1;
        b = 2;
        c.d = 3;
        foo.bar = 3;
      };
    };

    "test mkOverlay merging at two levels" = filterExprToExpected {
      expr = simpleScope.overrideScope (
        risingTideLib.mkOverlay [ "c" "e" ] (
          {
            a,
            b,
            c,
          }:
          a + b + c.d
        )
      );
      expected = {
        a = 1;
        b = 2;
        c.d = 3;
        c.e = 6;
      };
    };

    "test mkOverlay applies to a nested scope" = filterExprToExpected {
      expr = scopeWithNestedScope.overrideScope (
        risingTideLib.mkOverlay [ "nested" "baz" ] (
          {
            a,
            b,
            inner,
          }:
          a + b + inner
        )
      );
      expected = {
        a = 1;
        b = 2;
        c.d = 3;
        nested = {
          inner = 42;
          baz = 45;
        };
      };
    };
  };
}
