# rising-tide flake context
{ lib, self, ... }:
rec {
  mkBaseProject =
    {
      projectModules ? [ ],
    }:
    system: projectModule:
    (lib.evalModules {
      specialArgs = { inherit system projectModules; };
      modules = [
        self.modules.flake.project
        projectModule
        { relativePaths.toRoot = lib.mkDefault "./."; }
      ];
    }).config;

  mkProject =
    system: projectModule:
    mkBaseProject
      {
        projectModules = [
          self.modules.flake.risingTideConventions
          { conventions.risingTide.enable = true; }
        ];
      }
      system
      {
        imports = [ projectModule ];
      };

}
