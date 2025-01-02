# rising-tide flake context
{risingTideBootstrapLib, ...}:
# user flake context
flakeArgs @ {config, ...}: let
  injector = risingTideBootstrapLib.mkInjector "injector" {
    args = flakeArgs;
    getLazyArg = risingTideBootstrapLib.getLazyArgFromConfig config;
  };
in {
  _module.args = {inherit injector;};
  perSystem = perSystemArgs @ {config, ...}: let
    injector' = injector.mkChildInjector "injector'" {
      args = perSystemArgs;
      getLazyArg = risingTideBootstrapLib.getLazyArgFromConfig config;
    };
  in {
    _module.args = {inherit injector';};
  };
}
