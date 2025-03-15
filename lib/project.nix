# rising-tide flake context
{ lib, self, ... }:
let
  inherit (lib) types;
in
rec {
  mkBaseProject =
    {
      projectModules ? [ ],
      system ? (if pkgs != null then pkgs.system else basePkgs.system),
      basePkgs ? null,
      pkgs ? null,
      root ? null,
    }:
    rootProjectModule:
    let
      pkgs' =
        if pkgs != null then
          pkgs
        else if basePkgs != null then
          (basePkgs.extend projectConfig.overlay)
        else
          null;
      projectConfig =
        (lib.evalModules {
          specialArgs = {
            inherit system;
            projectModules = projectModules ++ [
              { config._module.args.pkgs = lib.mkIf (pkgs' != null) pkgs'; }
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
    in
    projectConfig;

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
          inherit (python-previous.pkgs.stdenv.hostPlatform) system;
        in
        rootProjectBySystem.${system}.languages.python.pythonOverlay python-final python-previous;

      overlays.default = (
        final: prev:
        let
          inherit (prev.stdenv.hostPlatform) system;
        in
        rootProjectBySystem.${system}.overlay final prev
      );
    in
    {
      inherit pythonOverlays overlays;
    };

  mkLifecycleTaskOption = name: {
    enable = (lib.mkEnableOption "Enable the ${name} task") // {
      default = true;
    };
    dependsOn = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "A list of task names that must complete before this task";
    };
    serialTasks = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "A list of task names that will be run serially by this task after all dependencies have completed.";
    };
  };
}
