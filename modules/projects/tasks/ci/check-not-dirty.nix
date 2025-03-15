# rising-tide flake context
{
  lib,
  ...
}:
# project context
{ config, ... }:
let
  cfg = config.tasks.ci.check-not-dirty;
in
{
  options = {
    tasks.ci.check-not-dirty = {
      enable = lib.mkEnableOption "Enable check-not-dirty task";
    };
  };

  config = lib.mkIf cfg.enable {
    tasks.ci.serialTasks = lib.mkAfter [ "ci:check-not-dirty" ];
    tools.go-task = {
      taskfile.tasks = {
        "ci:check-not-dirty" = {
          desc = "Check if the the git repo is dirty";
          cmds = [
            "git status"
            "git diff-files --compact-summary --exit-code ."
          ];
        };
      };
    };
  };
}
