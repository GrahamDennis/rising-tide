# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
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

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      allTools = ifEnabled [
        cfg.package
        toolsPkgs.ninja
      ];
      tools = {
        go-task = ifEnabled {
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
    };
}
