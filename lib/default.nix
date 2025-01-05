{
  lib,
  risingTide,
  ...
}:
let
  inherit (import ./injector.nix { inherit lib; }) mkInjector;
  injector = mkInjector "injector" {
    args = {
      inherit lib risingTide risingTideLib;
    };
  };
  risingTideLib = {
    attrs = injector.inject ./attrs.nix;
    injector = injector.inject ./injector.nix;
    project = injector.inject ./project.nix;
    strings = injector.inject ./strings.nix;
    tests = injector.inject ./tests.nix;
    types = injector.inject ./types.nix;

    inherit (risingTideLib.attrs) filterAttrsByPathRecursive;
    inherit (risingTideLib.injector) callWithLazyArgs mkInjector getLazyArgFromConfig;
    inherit (risingTideLib.strings) sanitizeBashIdentifier;
    inherit (risingTideLib.project) mkBaseProject mkProject;
  };
in
risingTideLib
