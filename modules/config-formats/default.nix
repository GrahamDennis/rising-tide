# rising-tide flake context
{ injector, ... }:
let
  commonModule = injector.injectModule ./common.nix;
in
builtins.mapAttrs
  (_name: module: {
    imports = [
      commonModule
      module
    ];
  })
  (
    injector.injectModules {
      mypy = ./mypy.nix;
      go-task = ./go-task;
    }
  )
