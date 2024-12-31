{lib}: 
  let
  _mkChildInjector = parentInjector: { args, injectorArgName ? "injector" }: let
      injector = {
        inherit inject injectModule;
        mkChildInjector = _mkChildInjector injector;
      };
      argsWithInjector = args // { "${injectorArgName}" = injector; };
      inject = fn: (parentInjector.inject fn) argsWithInjector;
      injectModule = modulePath: lib.setDefaultModuleLocation modulePath (inject modulePath);
    in injector;
  rootInjector = {
    inject = fn: if builtins.isFunction fn then fn else import fn;
    injectModule = modulePath: modulePath;
  };
  in
{
  mkInjector = _mkChildInjector rootInjector;
}