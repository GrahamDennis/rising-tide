# rising-tide bootstrap injector context
{ risingTideLib, ... }:
# user flake context
flakeArgs@{ config, ... }:
let
  injector = risingTideLib.mkInjector "injector" {
    args = flakeArgs;
    getLazyArg = risingTideLib.getLazyArgFromConfig config;
  };
in
{
  _module.args = { inherit injector; };
  perSystem =
    perSystemArgs@{ config, ... }:
    let
      injector' = injector.mkChildInjector "injector'" {
        args = perSystemArgs;
        getLazyArg = risingTideLib.getLazyArgFromConfig config;
      };
    in
    {
      _module.args = { inherit injector'; };
    };
}
