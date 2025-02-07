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
      mkShell.nativeBuildInputs = [
        cfg.package
        toolsPkgs.ninja
      ];
      tools = {
        go-task = {
          enable = true;
          # FIXME: Add gtest/ctest integration
          taskfile.tasks = {
            "build".deps = [ "build:cmake" ];
            "build:cmake" = {
              desc = "Build using CMake.";
              cmds = [
                "${cmakeExe} -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -G Ninja -S . -B build"
                "cmake --build build"
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
