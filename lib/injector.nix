# rising-tide flake context
{ lib, ... }:
let
  rootInjector = {
    inject = fn: if builtins.isFunction fn then fn else import fn;
  };
in
rec {
  /**
    Call function `fn` with arguments from `args` and additional arguments from
    the function signature lazily fetched by calling `getArg name`.
  */
  callWithLazyArgs =
    fn: args: getLazyArg:
    let
      context = name: ''while evaluating the function argument `${name}' for function `${fn}`:'';
      extraArgs =
        if getLazyArg != null then
          builtins.mapAttrs (
            name: _: lib.addErrorContext (context name) (args.${name} or (getLazyArg name))
          ) (lib.functionArgs fn)
        else
          { };
    in
    fn (args // extraArgs);

  /**
    Create a new injector with `parentInjector` as its parent.
    Prefer instead to call `mkInjector` to create a new root injector or
    `mkChildInjector` on an existing injector.
  */
  mkInjectorWithParent =
    parentInjector: name:
    {
      args ? { },
      getLazyArg ? null,
    }:
    let
      injector = {
        inherit inject injectModule injectModules;
        mkChildInjector = mkInjectorWithParent injector;
      };
      additionalInjectorArgs = {
        "${name}" = injector;
      };
      argsWithInjector = args // additionalInjectorArgs;
      inject = fn: callWithLazyArgs (parentInjector.inject fn) argsWithInjector getLazyArg;
      injectModule = modulePath: {
        _file = modulePath;
        key = modulePath;
        imports = [ (inject modulePath) ];
      };
      injectModules =
        modules:
        if builtins.isAttrs modules then
          builtins.mapAttrs (_name: injectModule) modules
        else if builtins.isList modules then
          builtins.map injectModule modules
        else
          throw "injectModules: expected a list or an attrset, got ${builtins.typeOf modules}";
    in
    injector;

  /**
    Create an injector that can be used to perform dependency injection / apply a scope to a function.
  */
  mkInjector = mkInjectorWithParent rootInjector;
  getLazyArgFromConfig = config: argName: config._module.args.${argName};
}
