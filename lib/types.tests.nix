# rising-tide flake context
{ lib, risingTideLib, ... }:
{
  subpath =
    let
      evalSubpath =
        value:
        (lib.evalModules {
          modules = [
            {
              options.subpath = lib.mkOption { type = risingTideLib.types.subpath; };
              config.subpath = value;
            }
          ];
        }).config.subpath;
    in
    {
      "test normalises path ." = {
        expr = evalSubpath ".";
        expected = "./.";
      };
      "test normalises path ./" = {
        expr = evalSubpath "./";
        expected = "./.";
      };
      "test normalises path foo/bar" = {
        expr = evalSubpath "foo/bar";
        expected = "./foo/bar";
      };
      "test `..` is forbidden" = {
        expr = evalSubpath "foo/../";
        expectedError.msg = ''a `\.\.` component, which is not allowed in subpaths'';
      };
    };

}
