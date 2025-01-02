# rising tide flake context
{injector, ...}: let
  modules.flake = builtins.mapAttrs (name: injector.injectModule) {
    project = ./modules/flake/projects/project.nix;
  };
in {
  flake = {
    inherit modules;
    lib = injector.inject ./lib;
    tests = builtins.mapAttrs (name: injector.inject) {
      lib = ./lib/tests;
      project = ./modules/flake/projects/project.tests.nix;
    };
  };

  perSystem = {
    pkgs,
    injector',
    ...
  }: {
    # FIXME: temporary
    packages.default = pkgs.emptyFile;

    devShells.default = injector'.inject ./devShell.nix;
  };
}
