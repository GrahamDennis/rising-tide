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
          { conventions.risingTide.enable = lib.mkDefault true; }
        ];
      }
      system
      {
        imports = [ projectModule ];
      };

  mkBaseProjectWith =
    {
      projectModules ? [ ],
      system ? null,
      pkgs ? null,
      root ? null,
    }:
    rootProjectModule:
    (lib.evalModules {
      specialArgs = {
        projectModules = projectModules ++ [
          { config._module.args.pkgs = lib.mkIf (pkgs != null) pkgs; }
        ];
      } // (if system != null then { inherit system; } else { inherit (pkgs) system; });
      modules = [
        self.modules.flake.project
        rootProjectModule
        {
          relativePaths.toRoot = lib.mkDefault "./.";
          absolutePath = lib.mkIf (root != null) root;
        }
      ];
    }).config;

  mkProjectWith =
    args@{
      projectModules ? [ ],
      ...
    }:
    mkBaseProjectWith (
      args
      // {
        projectModules = projectModules ++ [
          { conventions.risingTide.enable = lib.mkDefault true; }
        ];
      }
    );

}
