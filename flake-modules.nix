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
    risingTideConventions = ./modules/flake/projects/settings/conventions/rising-tide.nix;
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
      packages.documentation = pkgs.callPackage (injector.inject ./packages/documentation.nix) { };

      devShells.default = injector'.inject ./devShell.nix;
    };
}
