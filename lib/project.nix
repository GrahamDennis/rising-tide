# rising-tide flake context
{ lib, self, ... }:
rec {
  mkBaseProject =
    {
      projectModules ? [ ],
      system ? pkgs.system,
      pkgs ? null,
      root ? null,
    }:
    rootProjectModule:
    (lib.evalModules {
      specialArgs = {
        inherit system;
        projectModules = projectModules ++ [
          { config._module.args.pkgs = lib.mkIf (pkgs != null) pkgs; }
        ];
      };
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

  mkSystemIndependentOutputs =
    { rootProjectBySystem }:
    let
      pythonOverlays.default =
        python-final: python-previous:
        let
          inherit (python-previous.pkgs) system;
        in
        rootProjectBySystem.${system}.languages.python.pythonOverlay python-final python-previous;

      overlays.default = _final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [ pythonOverlays.default ];
      };
    in
    {
      inherit pythonOverlays overlays;
    };
}
