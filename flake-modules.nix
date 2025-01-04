# rising tide flake context
{ injector, ... }:
let
  modules.flake = injector.injectModules {
    project = ./modules/flake/projects/project.nix;
    risingTideConventions = ./modules/flake/projects/settings/conventions/rising-tide.nix;
  };
in
{
  flake = {
    inherit modules;
    lib = injector.inject ./lib;
    tests = builtins.mapAttrs (_name: injector.inject) {
      lib = ./lib/tests;
      project = ./modules/flake/projects/project.tests.nix;
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
