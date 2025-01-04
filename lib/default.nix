{
  lib,
  risingTide,
  ...
}:
let
  risingTideInjectorLib = import ./injector.nix { inherit lib; };
  injector = risingTideInjectorLib.mkInjector "injector" {
    args = {
      inherit lib risingTide risingTideLib;
    };
  };
  risingTideLib = {
    attrs = injector.inject ./attrs.nix;
    injector = injector.inject ./injector.nix;
    project = injector.inject ./project.nix;
    strings = injector.inject ./strings.nix;
    testutils = injector.inject ./testutils.nix;
    types = injector.inject ./types.nix;

    inherit (risingTideLib.attrs) filterAttrsByPathRecursive;
    inherit (risingTideLib.injector) callWithLazyArgs mkInjector getLazyArgFromConfig;
    inherit (risingTideLib.strings) sanitizeBashIdentifier;
    inherit (risingTideLib.project) mkBaseProject mkProject;
  };
in
risingTideLib
