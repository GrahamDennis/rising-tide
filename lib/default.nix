# rising-tide flake context
{
  lib,
  self,
  inputs,
  ...
}:
let
  inherit (import ./injector.nix { inherit lib; }) mkInjector;
  injector = mkInjector "injector" {
    args = {
      inherit
        lib
        self
        inputs
        risingTideLib
        ;
    };
  };
  risingTideLib = {
    attrs = injector.inject ./attrs.nix;
    injector = injector.inject ./injector.nix;
    nixagoEngines = injector.inject ./nixagoEngines.nix;
    overlays = injector.inject ./overlays.nix;
    perSystem = injector.inject ./perSystem;
    project = injector.inject ./project.nix;
    strings = injector.inject ./strings.nix;
    tests = injector.inject ./tests.nix;
    types = injector.inject ./types.nix;

    inherit (risingTideLib.attrs)
      filterAttrsByPathRecursive
      flattenAttrsRecursive
      flattenAttrsRecursiveCond
      ;
    inherit (risingTideLib.injector) callWithLazyArgs mkInjector getLazyArgFromConfig;
    inherit (risingTideLib.strings) sanitizeBashIdentifier;
    inherit (risingTideLib.overlays) mkOverlay;
    inherit (risingTideLib.project) mkBaseProject mkProject;
  };
in
risingTideLib
