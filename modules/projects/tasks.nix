# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  ...
}:
let
  inherit (lib) types;
  enabledModule = types.submodule (
    { name, ... }:
    {
      options.enable = lib.mkEnableOption "Enable task ${name}";
    }
  );
  cfg = config.tasks;
in
{
  options.tasks = {
    check = {
      enable = (lib.mkEnableOption "Enable the check task") // {
        default = true;
      };
      serialTasks = lib.mkOption {
        type = types.attrsOf enabledModule;
        default = { };
        description = ''
          Tasks that should be run serially as part of the check task. Check tasks should be added
          here if they modify files, for example to format them. Prefer to add such tasks as part
          of `treefmt` if they operate on a single file at a time as treefmt performs parallelisation
          across files.
        '';
        example = {
          "check:treefmt".enable = true;
        };
      };
      concurrentTasks = lib.mkOption {
        type = types.attrsOf enabledModule;
        default = { };
        example = {
          "check:mypy".enable = true;
          "check:ctest".enable = true;
        };
        description = ''
          Tasks that can be run concurrently as part of the check task. Check tasks should be added here
          if they do not modify files.
        '';
      };
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.check.enable {
      tools.go-task = {
        taskfile.tasks = {
          check = {
            desc = "Run all checks";
            aliases = [
              "lint"
              "format"
              "fmt"
            ];
            cmds = [
              { task = "check:_serial"; }
              { task = "check:_concurrent"; }
            ];
          };
          "check:_serial" = {
            internal = true;
            cmds = lib.pipe cfg.check.serialTasks [
              (lib.filterAttrs (_name: taskCfg: taskCfg.enable))
              (lib.mapAttrsToList (name: _taskCfg: { task = name; }))
            ];
          };
          "check:_concurrent" = {
            internal = true;
            deps = lib.pipe cfg.check.concurrentTasks [
              (lib.filterAttrs (_name: taskCfg: taskCfg.enable))
              builtins.attrNames
            ];
          };
        };
      };
    })
  ];
}
