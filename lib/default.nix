{lib}: 
  let
  # Call function `fn` with arguments lazily fetched by calling `getArg name` for each named
  # argument in the function's signature.
  callWithLazyArgs = fn: args: getLazyArg: let
      context = name: ''while evaluating the function argument `${name}':'';
      extraArgs = if getLazyArg != null then builtins.mapAttrs (name: _: lib.addErrorContext (context name) (args.${name} or (getLazyArg name)) ) (lib.functionArgs fn) else {};
      in fn (args // extraArgs);

  _mkInjector = parentInjector: { args ? {}, getLazyArg ? null, name ? "injector" }: let
      injector = {
        inherit inject injectModule;
        mkChildInjector = _mkInjector injector;
      };
      additionalInjectorArgs = { "${name}" = injector; };
      argsWithInjector = args // additionalInjectorArgs;
      inject = fn: callWithLazyArgs (parentInjector.inject fn) argsWithInjector getLazyArg;
      injectModule = modulePath: lib.setDefaultModuleLocation modulePath (inject modulePath);
    in injector;
  rootInjector = {
    inject = fn: if builtins.isFunction fn then fn else import fn;
  };
  in
{
  inherit callWithLazyArgs;
  mkInjector = _mkInjector rootInjector;
  getLazyArgFromConfig = config: argName: config._module.args.${argName};
}