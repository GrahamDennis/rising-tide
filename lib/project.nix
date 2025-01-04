{ lib, risingTide, ... }:
rec {
  mkBaseProject =
    projectModule:
    (lib.evalModules {
      modules = [
        risingTide.modules.flake.project
        projectModule
        { relativePaths.toRoot = lib.mkDefault "./."; }
      ];
    }).config;

  mkProject =
    projectModule:
    mkBaseProject {
      imports = [ projectModule ];
      config.defaultSettings = risingTide.modules.flake.risingTideConventions;
    };

}
