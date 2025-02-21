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
      tasks.build.dependsOn = [ "cmake:build" ];
      tasks.test.dependsOn = [ "test:ctest" ];
      tools = {
        go-task = {
          enable = true;
          # FIXME: Add gtest/ctest integration
          taskfile.tasks = {
            "cmake:build" = {
              desc = "Build using CMake.";
              cmds = [
                "${cmakeExe} -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -GNinja -S . -B build"
                "cmake --build build"
              ];
            };
            "test:ctest" = {
              desc = "Run CTest";
              dir = "build/tests";
              cmds = [
                "ctest"
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
        "cmake.configureArgs" = [
          "-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE"
          "-GNinja"
        ];
      };
    })
  ];
}
