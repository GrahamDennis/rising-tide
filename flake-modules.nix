# rising tide flake context
{
  injector,
  lib,
  risingTideLib,
  ...
}:
{
  flake = {
    modules.flake = injector.injectModules {
      project = ./modules/projects/project.nix;
    };
    lib = risingTideLib;

    tests = injector.inject ./tests;
  };

  perSystem =
    {
      pkgs,
      injector',
      config,
      ...
    }:
    {
      packages.default = config.packages.all-checks;
      packages.project-module-docs =
        pkgs.callPackage (injector.inject ./packages/project-module-docs.nix)
          { };
      packages.lib-docs = pkgs.callPackage (injector.inject ./packages/lib-docs.nix) { };
      packages.all-checks = pkgs.linkFarm "all-checks" (
        risingTideLib.flattenAttrsRecursiveCond (v: !(lib.isDerivation v)) config.legacyPackages.checks
      );

      devShells.default = injector'.inject ./devShell.nix;

      legacyPackages =
        let
          overrideDerivationName =
            path: drv: drv.overrideAttrs { name = "checks.${builtins.concatStringsSep "." path}"; };
        in
        {
          checks = lib.mapAttrsRecursiveCond (value: !(lib.isDerivation value)) overrideDerivationName (
            injector'.inject ./checks
          );
        };

    };
}
