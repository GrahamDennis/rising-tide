# rising-tide flake context
{ lib, self, ... }:
let
  inherit (import ./injector.nix { inherit lib; }) mkInjector;
  injector = mkInjector "injector" {
    args = {
      inherit lib self risingTideLib;
    };
  };
  risingTideLib = {
    attrs = injector.inject ./attrs.nix;
    configFormats = injector.inject ./config-formats.nix;
    injector = injector.inject ./injector.nix;
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
    inherit (risingTideLib.project) mkBaseProject mkProject;
  };
in
risingTideLib
