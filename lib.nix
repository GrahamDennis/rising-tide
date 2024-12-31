{lib}: {
  mkInjector = injectionArgs: let
    args = injectionArgs // { inherit inject injectModule; };
    injectModule = modulePath: lib.setDefaultModuleLocation modulePath (inject modulePath);
    inject = fn: let
      f = if builtins.isFunction fn then fn else import fn;
    in
      f args;
  in {
    inherit inject injectModule;
  };
}