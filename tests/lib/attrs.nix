# rising-tide flake context
{ risingTideLib, ... }:
{
  "test filterAttrsByPathRecursive can drop subattrs" = {
    expr =
      risingTideLib.filterAttrsByPathRecursive
        (
          path: _v:
          path != [
            "a"
            "b"
          ]
        )
        {
          a.a = 1;
          a.b.c = 2;
          a.d = 3;
        };
    expected = {
      a.a = 1;
      a.d = 3;
    };
  };
  "test filterAttrsByPathRecursive drops leaves" = {
    expr =
      risingTideLib.filterAttrsByPathRecursive
        (
          path: _v:
          path != [
            "a"
            "b"
            "c"
          ]
        )
        {
          a.a = 1;
          a.b.c = 2;
          a.d = 3;
        };
    expected = {
      a.a = 1;
      a.b = { };
      a.d = 3;
    };
  };

  "test flattenAttrsRecursive" = {
    expr = risingTideLib.flattenAttrsRecursive {
      a.a = 1;
      a.b.c = 2;
      a.d = 3;
    };
    expected = {
      "a.a" = 1;
      "a.b.c" = 2;
      "a.d" = 3;
    };
  };
}
