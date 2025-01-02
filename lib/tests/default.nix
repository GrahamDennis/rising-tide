{
  lib,
  risingTideLib,
  ...
}: {
  mkInjector = let
    inherit (risingTideLib) mkInjector;
  in {
    "test inject" = let
      injector = mkInjector "injector" {
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
      injector = mkInjector "inj" {
        args = {
          foo = 1;
          bar = 2;
        };
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
      injector = mkInjector "injector" {
        args = {
          foo = 1;
          bar = 2;
        };
      };
      injector' = injector.mkChildInjector "injector'" {
        args = {
          foo = 3;
          baz = 3;
        };
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

    injectModule = let
      injector = mkInjector "injector" {
        args = {
          foo = 1;
          bar = 2;
        };
      };
      expectedModule = {
        _file = ./module.nix;
        imports = [{foo = 1;}];
      };
    in {
      "test injectModule" = {
        expr = injector.injectModule ./module.nix;
        expected = expectedModule;
      };
      "test injectModules with list" = {
        expr = injector.injectModules [./module.nix ./module.nix];
        expected = [expectedModule expectedModule];
      };
      "test injectModules with attrs" = {
        expr = injector.injectModules {
          a = ./module.nix;
          b = ./module.nix;
        };
        expected = {
          a = expectedModule;
          b = expectedModule;
        };
      };
    };
  };

  mkProject = let
    inherit (risingTideLib) mkProject;
  in {
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
        allSystems.x86_64-linux = {};
        tools.x86_64-linux = {};
      };
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
