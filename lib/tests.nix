{risingTideLib, ...}: let
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
      injectorArgName = "inj";
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
    injector' = injector.mkChildInjector { args = {foo = 3; baz = 3; }; injectorArgName = "injector'";};
    fn = { bar, ... }: { foo, baz, ...}: foo + bar + baz;
  in {
    expr = injector'.inject fn;
    expected = 8;
  };
}
