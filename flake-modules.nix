# rising tide flake context
{
  injector,
  lib,
  risingTideLib,
  inputs,
  ...
}:
let
  inherit (lib) types;
in
{
  imports = [
    # FIXME: Create a proper flake-parts module for project
    (inputs.flake-parts.lib.mkTransposedPerSystemModule {
      name = "project";
      option = lib.mkOption {
        type = types.raw;
        default = null;
      };
      file = ./flake-modules.nix;
    })
  ];
  config = {
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
      let
        project = injector'.inject ./project.nix;
      in
      {
        inherit project;
        packages = project.packages // {
          default = config.packages.all-checks;
          project-module-docs = pkgs.callPackage (injector.inject ./packages/project-module-docs.nix) { };
          lib-docs = pkgs.callPackage (injector.inject ./packages/lib-docs.nix) { };
          all-checks = pkgs.linkFarm "all-checks" (
            risingTideLib.flattenAttrsRecursiveCond (v: !(lib.isDerivation v)) config.legacyPackages.checks
          );
          clangd-tidy = pkgs.python3Packages.callPackage ./packages/clangd-tidy.nix { };
          go-task-patched = pkgs.go-task.overrideAttrs (_drv: {
            pname = "go-task-patched";
            version = "3.43.3";
            src = pkgs.fetchFromGitHub {
              owner = "GrahamDennis";
              repo = "task";
              rev = "01f71efc92a7d889f2f244170a81b36e5708820c";
              hash = "sha256-qtZrrrGVWR4CuskB8KN7sta0oy20fPSE70Vpjhj32ls=";
            };

            vendorHash = "sha256-3Uu0ozwOgp6vQh+s9nGKojw6xPUI49MjjPqKh9g35lQ=";
          });
        };

        inherit (project) devShells;

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
  };
}
