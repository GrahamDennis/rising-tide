{
  lib,
  risingTide,
  ...
}:
let
  risingTideBootstrapLib = import ./bootstrap.nix { inherit lib; };
  risingTideLib = lib.makeExtensible (
    self:
    let
      injector = risingTideBootstrapLib.mkInjector "injector" {
        args = {
          inherit lib risingTide;
          risingTideLib = self;
        };
      };
    in
    {
      inherit injector;

      attrs = injector.inject ./attrs.nix;
      bootstrap = injector.inject ./bootstrap.nix;
      project = injector.inject ./project.nix;
      strings = injector.inject ./strings.nix;
      testutils = injector.inject ./testutils.nix;
      types = injector.inject ./types.nix;

      inherit (self.attrs) filterAttrsByPathRecursive;
      inherit (self.bootstrap) callWithLazyArgs mkInjector getLazyArgFromConfig;
      inherit (self.strings) sanitizeBashIdentifier;
      inherit (self.project) mkBaseProject mkProject;
    }
  );
in
risingTideLib
