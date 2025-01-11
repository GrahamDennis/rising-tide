{ lib, risingTide, ... }:
rec {
  mkBaseProject =
    {
      projectModules ? [ ],
    }:
    system: projectModule:
    (lib.evalModules {
      specialArgs = { inherit system projectModules; };
      modules = [
        risingTide.modules.flake.project
        projectModule
        { relativePaths.toRoot = lib.mkDefault "./."; }
      ];
    }).config;

  mkProject =
    system: projectModule:
    mkBaseProject
      {
        projectModules = [ risingTide.modules.flake.risingTideConventions ];
      }
      system
      {
        imports = [ projectModule ];
      };

}
