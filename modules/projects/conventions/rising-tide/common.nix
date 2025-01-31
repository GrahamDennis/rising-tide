# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  cfg = config.conventions.risingTide.common;
in
{
  options.conventions.risingTide.common = {
    enable = lib.mkEnableOption "Enable rising-tide common conventions";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        tools.go-task = {
          enable = true;
          taskfile.run = "when_changed";
          taskfile.tasks = {
            test.desc = "Run all tests";
            check = {
              desc = "Run all checks";
              aliases = [
                "lint"
                "format"
                "fmt"
              ];
            };
            build.desc = "Build";
          };
        };
      }
      (lib.mkIf config.isRootProject {
        tools.vscode.enable = true;
      })
    ]
  );
}
