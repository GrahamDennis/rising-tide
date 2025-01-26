# rising-tide flake context
{ lib, self, ... }:
rec {
  mkBaseProject =
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

  mkProject =
    args@{
      projectModules ? [ ],
      ...
    }:
    mkBaseProject (
      args
      // {
        projectModules = projectModules ++ [
          { conventions.risingTide.enable = lib.mkDefault true; }
        ];
      }
    );

}
