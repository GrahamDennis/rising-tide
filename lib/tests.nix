{
  lib,
  risingTideLib,
  ...
}: {
  mkInjector = let
  inherit (risingTideLib) mkInjector;
in {
    "test inject" = let
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

    "test inject with a custom injector argument name" = let
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

    "test mkChildInjector" = let
      injector = mkInjector {
        args = {
          foo = 1;
          bar = 2;
        };
      };
      injector' = injector.mkChildInjector {
        args = {
          foo = 3;
          baz = 3;
        };
        name = "injector'";
      };
      fn = {bar, ...}: {
        foo,
        baz,
        ...
      }:
        foo + bar + baz;
    in {
      expr = injector'.inject fn;
      expected = 8;
    };
  };

  mkProject = let inherit (risingTideLib) mkProject; in {
    "test defaults" = risingTideLib.tests.filterExprToExpected {
      expr = mkProject {
        name = "example-project";
        systems = ["x86_64-linux"];
      };
      expected = {
        name = "example-project";
        relativePaths = {
          toRoot = "./.";
          toParentProject = null;
          parentProjectToRoot = null;
        };
        subprojects = {};
        systems = ["x86_64-linux"];
        allSystems.x86_64-linux = { };
        tools.x86_64-linux = {};
      };
    };
    "test go-task" = let project = mkProject {
      name = "example-project";
      systems = ["x86_64-linux"];
      perSystem.tools.go-task = {
        enable = true;
      };
    }; in {
      # How can we improve this?
      expr = builtins.length project.tools.x86_64-linux.nativeCheckInputs;
      expected = 2;
    };
  };

  types.subpath = let
    evalSubpath = value:
      (lib.evalModules {
        modules = [
          {
            options.subpath = lib.mkOption {type = risingTideLib.types.subpath;};
            config.subpath = value;
          }
        ];
      })
      .config
      .subpath;
  in {
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
