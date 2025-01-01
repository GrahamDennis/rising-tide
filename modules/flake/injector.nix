# rising-tide flake context
{risingTideLib, ...}:
# user flake context
flakeArgs @ {config, ...}: let
  injector = risingTideLib.mkInjector {
    args = flakeArgs;
    getLazyArg = risingTideLib.getLazyArgFromConfig config;
  };
in {
  _module.args = {inherit injector;};
  perSystem = perSystemArgs @ {config, ...}: let
    injector' = injector.mkChildInjector {
      args = perSystemArgs;
      getLazyArg = risingTideLib.getLazyArgFromConfig config;
      name = "injector'";
    };
  in {
    _module.args = {inherit injector';};
  };
}
