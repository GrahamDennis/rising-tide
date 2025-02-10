# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
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
        tools.shellHooks = {
          enable = true;
          hooks.bashCompletion = ''
            . "${toolsPkgs.bash-completion}/etc/profile.d/bash_completion.sh"
          '';
        };
        tools.go-task = {
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
        tools.jetbrains.enable = true;
      })
    ]
  );
}
