# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  enabledIn = projectConfig: projectConfig.tools.cmake.enable;
  cfg = config.tools.cmake;
  cmakeExe = lib.getExe cfg.package;
in
{
  options = {
    tools.cmake = {
      enable = lib.mkEnableOption "Enable cmake integration";
      package = lib.mkPackageOption toolsPkgs "cmake" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      allTools = [
        cfg.package
        toolsPkgs.ninja
      ];
      tools = {
        go-task = {
          enable = true;
          taskfile.tasks = {
            "build:cmake" = {
              desc = "Build using CMake.";
              cmds = [
                "${cmakeExe} -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -G Ninja -S . -B build"
                "cd build; ninja"
              ];
            };
            "tool:cmake" = {
              desc = "Run cmake. Additional CLI arguments after `--` are forwarded to cmake";
              cmds = [ "${cmakeExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.vscode.settings = {
        "cmake.ctest.testExplorerIntegrationEnabled" = false;
      };
    })
  ];
}
