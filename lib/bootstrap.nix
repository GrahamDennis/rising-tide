{ lib }:
let
  inherit (lib) types;
  # Call function `fn` with arguments from `args` and additional arguments from the function signature lazily fetched
  # by calling `getArg name`
  callWithLazyArgs =
    fn: args: getLazyArg:
    let
      context = name: ''while evaluating the function argument `${name}':'';
      extraArgs =
        if getLazyArg != null then
          builtins.mapAttrs (
            name: _: lib.addErrorContext (context name) (args.${name} or (getLazyArg name))
          ) (lib.functionArgs fn)
        else
          { };
    in
    fn (args // extraArgs);

  _mkInjector =
    parentInjector: name:
    {
      args ? { },
      getLazyArg ? null,
    }:
    let
      injector = {
        inherit inject injectModule injectModules;
        mkChildInjector = _mkInjector injector;
      };
      additionalInjectorArgs = {
        "${name}" = injector;
      };
      argsWithInjector = args // additionalInjectorArgs;
      inject = fn: callWithLazyArgs (parentInjector.inject fn) argsWithInjector getLazyArg;
      injectModule = modulePath: lib.setDefaultModuleLocation modulePath (inject modulePath);
      injectModules =
        modules:
        if builtins.isAttrs modules then
          builtins.mapAttrs (_name: module: injectModule module) modules
        else if builtins.isList modules then
          builtins.map injectModule modules
        else
          throw "injectModules: expected a list or an attrset, got ${builtins.typeOf modules}";
    in
    injector;
  rootInjector = {
    inject = fn: if builtins.isFunction fn then fn else import fn;
  };
in
{
  inherit callWithLazyArgs;
  mkInjector = _mkInjector rootInjector;
  getLazyArgFromConfig = config: argName: config._module.args.${argName};
  types = {
    subpath = types.str // {
      name = "subpath";
      description = "A relative path";
      merge = loc: defs: lib.path.subpath.normalise (lib.mergeEqualOption loc defs);
    };
  };
}
