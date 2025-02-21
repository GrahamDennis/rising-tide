# rising-tide flake context
{ lib, risingTideLib, ... }:
let
  nixpkgs2211 = builtins.fetchTree {
    type = "tarball";
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-22.11.tar.gz";
    narHash = "sha256-lHrKvEkCPTUO+7tPfjIcb7Trk6k31rz18vkyqmkeJfY=";
  };
  nixpkgs2405 = builtins.fetchTree {
    type = "tarball";
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
    narHash = "sha256-OnSAY7XDSx7CtDoqNh8jwVwh4xNL/2HaJxGjryLWzX8=";
  };
  lib2211 = import "${nixpkgs2211}/lib";
  lib2405 = import "${nixpkgs2405}/lib";
  inherit (risingTideLib.tests) filterExprToExpected;

  mkOverlayTests =
    lib: overrideScope:
    let
      simpleScope = lib.makeScope (extra: lib.callPackageWith extra) (_self: {
        a = 1;
        b = 2;
        c.d = 3;
      });
      scopeWithNestedScope = simpleScope.${overrideScope} (
        final: _prev: {
          nested = lib.makeScope final.newScope (_self: {
            inner = 42;
            very.deeply.nested = 43;
          });
        }
      );

    in
    {
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
        expr = simpleScope.${overrideScope} (risingTideLib.mkOverlay [ "foo" ] ({ a, b }: a + b));
        expected = {
          a = 1;
          b = 2;
          c.d = 3;
          foo = 3;
        };
      };

      "test mkOverlay at two levels" = filterExprToExpected {
        expr = simpleScope.${overrideScope} (risingTideLib.mkOverlay [ "foo" "bar" ] ({ a, b }: a + b));
        expected = {
          a = 1;
          b = 2;
          c.d = 3;
          foo.bar = 3;
        };
      };

      "test mkOverlay merging at two levels" = filterExprToExpected {
        expr = simpleScope.${overrideScope} (
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
        expr = scopeWithNestedScope.${overrideScope} (
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

      "test mkOverlay applies to a nested scope (deeply)" = filterExprToExpected {
        expr = scopeWithNestedScope.${overrideScope} (
          risingTideLib.mkOverlay [ "nested" "very" "deeply" "peer" ] (
            {
              a,
              b,
              very,
            }:
            a + b + very.deeply.nested
          )
        );
        expected = {
          a = 1;
          b = 2;
          c.d = 3;
          nested = {
            inner = 42;
            very.deeply.nested = 43;
            very.deeply.peer = 46;
          };
        };
      };
    };
in
{
  mkOverlay = {
    lib = mkOverlayTests lib "overrideScope";
    lib2211 = mkOverlayTests lib2211 "overrideScope'";
    lib2405 = mkOverlayTests lib2405 "overrideScope";
  };
}
