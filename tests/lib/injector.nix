# rising-tide flake context
{ risingTideLib, lib, ... }:
let
  inherit (risingTideLib) mkInjector;
in
{
  "test inject" =
    let
      injector = mkInjector "injector" {
        args = {
          foo = 1;
          bar = 2;
        };
      };
      fn =
        {
          foo,
          bar,
          # This line is present to validate that the argument name injector is provided
          # deadnix: skip
          injector,
        }:
        foo + bar;
    in
    {
      expr = injector.inject fn;
      expected = 3;
    };

  "test inject with a custom injector argument name" =
    let
      injector = mkInjector "inj" {
        args = {
          foo = 1;
          bar = 2;
        };
      };
      fn =
        {
          foo,
          bar,
          # This line is present to validate that the argument name inj is provided
          # deadnix: skip
          inj,
        }:
        foo + bar;
    in
    {
      expr = injector.inject fn;
      expected = 3;
    };

  "test mkChildInjector" =
    let
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
      fn =
        { bar, ... }:
        {
          foo,
          baz,
          ...
        }:
        foo + bar + baz;
    in
    {
      expr = injector'.inject fn;
      expected = 8;
    };

  injectModule =
    let
      injector = mkInjector "injector" {
        args = {
          foo = 1;
          bar = 2;
        };
      };
      expectedModule = {
        _file = ./test-modules/copy-foo.nix;
        key = ./test-modules/copy-foo.nix;
        imports = [ { foo = 1; } ];
      };
    in
    {
      "test injectModule" = {
        expr = injector.injectModule ./test-modules/copy-foo.nix;
        expected = expectedModule;
      };
      "test injectModules with list" = {
        expr = injector.injectModules [
          ./test-modules/copy-foo.nix
          ./test-modules/copy-foo.nix
        ];
        expected = [
          expectedModule
          expectedModule
        ];
      };
      "test injectModules with attrs" = {
        expr = injector.injectModules {
          a = ./test-modules/copy-foo.nix;
          b = ./test-modules/copy-foo.nix;
        };
        expected = {
          a = expectedModule;
          b = expectedModule;
        };
      };

      errors =
        let
          expectedErrorMessages = {
            fnCalledWithoutBar = "function '.*fn.*' called without required argument '.*bar.*'";
            anonymousLambdaCalledWithoutBar = "function '.*anonymous lambda.*' called without required argument '.*bar.*'";
          };
        in
        {
          "test exception message of normal function" =
            let
              fn = { foo, bar, ... }: foo + bar;
            in
            {
              expr = fn { foo = 1; };
              expectedError.msg = expectedErrorMessages.fnCalledWithoutBar;
            };
          "test exception message of anonymous lambda" = {
            expr = ({ foo, bar, ... }: foo + bar) { foo = 1; };
            expectedError.msg = expectedErrorMessages.anonymousLambdaCalledWithoutBar;
          };
          "test exception message of injected normal function" =
            let
              injector = mkInjector "injector" { };
              # deadnix: skip
              fn = { injector, ... }: ({ foo, bar, ... }: foo + bar);
            in
            {
              expr = (injector.inject fn) { foo = 1; };
              expectedError.msg = expectedErrorMessages.fnCalledWithoutBar;
            };
          "test error raised due to conflicts mentions the injected file name" =
            let
              injector = mkInjector "injector" { };
            in
            {
              expr =
                (lib.evalModules {
                  modules = injector.injectModules [
                    ./test-modules/test-conflicts-1.nix
                    ./test-modules/test-conflicts-2.nix
                  ];
                }).config;
              expectedError.msg = ".*test-conflicts-.*";
            };
        };
    };

  injectModuleWithDuplicates =
    let
      injector = mkInjector "injector" {
        args = {
        };
      };
      expected = {
        foo = 42;
      };
    in
    {
      # Validate that despite injectModules, the two module imports get deduplicated
      "test injectModule" = {
        expr =
          (lib.evalModules {
            modules = injector.injectModules [
              ./test-modules/deduplication.nix
              ./test-modules/deduplication.nix
            ];
          }).config;
        inherit expected;
      };
    };

}
