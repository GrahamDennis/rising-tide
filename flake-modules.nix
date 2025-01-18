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
      project = ./modules/flake/projects/project.nix;
      risingTideConventions = ./modules/flake/projects/settings/conventions/rising-tide;
    };
    modules.configFormats = injector.inject ./modules/config-formats;
    lib = risingTideLib;

    tests = lib.mapAttrsRecursive (_path: injector.inject) {
      lib = ./lib/default.tests.nix;
      modules.flake.project = ./modules/flake/projects/project.tests.nix;
    };
  };

  perSystem =
    {
      pkgs,
      injector',
      config,
      system,
      ...
    }:
    {
      packages.default = config.packages.all-checks;
      packages.project-module-docs =
        pkgs.callPackage (injector.inject ./packages/project-module-docs.nix)
          { };
      packages.lib-docs = pkgs.callPackage (injector.inject ./packages/lib-docs.nix) { };
      packages.all-checks = pkgs.linkFarm "all-checks" config.checks;

      devShells.default = injector'.inject ./devShell.nix;

      checks =
        let
          updateDerivationNames = builtins.mapAttrs (
            name: drv: drv.overrideAttrs { name = "checks.${system}.${name}"; }
          );
          flatten = risingTideLib.flattenAttrsRecursiveCond (as: !(lib.isDerivation as));
        in
        updateDerivationNames (flatten {
          config-formats = injector'.inject ./modules/config-formats/checks;
        });
    };
}
