{lib, risingTideLib, ...}: let
  inherit (risingTideLib) mkInjector;
in {
  "test mkInjector{...}.inject" = let
    injector = mkInjector {
      args = {
        foo = 1;
        bar = 2;
      };
    };
    fn = {
      foo,
      bar,
      injector,
    }:
      foo + bar;
  in {
    expr = injector.inject fn;
    expected = 3;
  };

  "test mkInjector{...}.inject with a custom injector argument name" = let
    injector = mkInjector {
      args = {
        foo = 1;
        bar = 2;
      };
      name = "inj";
    };
    fn = {
      foo,
      bar,
      inj,
    }:
      foo + bar;
  in {
    expr = injector.inject fn;
    expected = 3;
  };

  "test mkInjector{...}.mkChildInjector" = let
    injector = mkInjector { args = {foo = 1; bar = 2; }; };
    injector' = injector.mkChildInjector { args = {foo = 3; baz = 3; }; name = "injector'";};
    fn = { bar, ... }: { foo, baz, ...}: foo + bar + baz;
  in {
    expr = injector'.inject fn;
    expected = 8;
  };

  types.subpath = let evalSubpath = value: (lib.evalModules {
    modules = [ {
      options.subpath = lib.mkOption { type = risingTideLib.types.subpath; };
      config.subpath = value;
    }];
  }).config.subpath; in {
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
