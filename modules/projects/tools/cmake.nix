# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  getCfg = projectConfig: projectConfig.tools.cmake;
  cfg = getCfg config;
  isEnabledIn = projectConfig: (getCfg projectConfig).enable;
  cmakeExe = lib.getExe cfg.package;
in
{
  options = {
    tools.cmake = {
      enable = lib.mkEnableOption "Enable cmake integration";
      package = lib.mkPackageOption toolsPkgs "cmake" { pkgsText = "toolsPkgs"; };
      generator = lib.mkOption {
        type = types.str;
        description = "The CMake generator to use";
        default = "Unix Makefiles";
      };
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
        gitignore = {
          enable = true;
          rules = ''
            # CMake build directory
            /build/
          '';
        };
        go-task = {
          enable = true;
          # FIXME: Add gtest/ctest integration
          taskfile.tasks = {
            "cmake:configure" = {
              desc = "Configure using CMake.";
              cmds = [
                "${cmakeExe} -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE \"-G${cfg.generator}\" -S . -B build"
              ];
            };
            "cmake:build" = {
              desc = "Build using CMake.";
              deps = [ "cmake:configure" ];
              cmds = [
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
        vscode.settings = {
          "cmake.configureArgs" = [
            "-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE"
            "-G${cfg.generator}"
          ];
        };
      };
    })

    (lib.mkIf (!cfg.enable && (builtins.any isEnabledIn config.subprojectsList)) {
      tools.vscode.settings = {
        "cmake.ignoreCMakeListsMissing" = true;
      };
    })
  ];
}
