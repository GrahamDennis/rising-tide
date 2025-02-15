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
          taskfile.run = "when_changed";
        };
        tools.shellcheck = {
          config.disable = [ "SC1091" ];
        };
      }
      (lib.mkIf config.isRootProject {
        tools.vscode.enable = true;
        tools.jetbrains.enable = true;
      })
    ]
  );
}
