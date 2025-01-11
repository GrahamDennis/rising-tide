# rising tide flake context
{
  injector,
  lib,
  risingTideLib,
  ...
}:
let
  modules.flake = injector.injectModules {
    project = ./modules/flake/projects/project.nix;
    risingTideConventions = ./modules/flake/projects/settings/conventions/rising-tide;
  };
in
{
  flake = {
    inherit modules;
    lib = risingTideLib;
    tests = lib.mapAttrsRecursive (_path: injector.inject) {
      lib = {
        injector = ./lib/injector.tests.nix;
        project = ./lib/project.tests.nix;
        types = ./lib/types.tests.nix;
      };
      modules.flake.project = ./modules/flake/projects/project.tests.nix;
    };
  };

  perSystem =
    {
      pkgs,
      injector',
      ...
    }:
    {
      # FIXME: temporary
      packages.default = pkgs.emptyFile;
      packages.project-module-docs =
        pkgs.callPackage (injector.inject ./packages/project-module-docs.nix)
          { };
      packages.lib-docs = pkgs.callPackage (injector.inject ./packages/lib-docs.nix) { };

      devShells.default = injector'.inject ./devShell.nix;
    };
}
