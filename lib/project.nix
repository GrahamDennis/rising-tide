{ lib, risingTide, ... }:
rec {
  mkBaseProject =
    system: projectModule:
    (lib.evalModules {
      specialArgs = { inherit system; };
      modules = [
        risingTide.modules.flake.project
        projectModule
        { relativePaths.toRoot = lib.mkDefault "./."; }
      ];
    }).config;

  mkProject =
    system: projectModule:
    mkBaseProject system {
      imports = [ projectModule ];
      config.defaultSettings = risingTide.modules.flake.risingTideConventions;
    };

}
