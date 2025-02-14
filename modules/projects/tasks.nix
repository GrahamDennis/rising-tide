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
  cfg = config.tasks;
  mkTasks =
    names:
    lib.genAttrs names (name: {
      enable = (lib.mkEnableOption "Enable the ${name} task") // {
        default = true;
      };
      dependsOn = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "A list of task names that must complete before this task";
      };
      serialTasks = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "A list of task names that will be run serially by this task after all dependencies have completed.";
      };
    });
  tasksToCmds = builtins.map (name: {
    task = name;
  });
  ifNotEmpty = tasks: lib.mkIf (tasks != [ ]) tasks;
in
{
  options.tasks = mkTasks [
    "build"
    "check"
    "test"
  ];
  config = lib.mkMerge [
    (lib.mkIf cfg.build.enable {
      tools.go-task = {
        taskfile.tasks = {
          build = {
            desc = "Build";
            deps = ifNotEmpty cfg.build.dependsOn;
            cmds = ifNotEmpty (tasksToCmds cfg.build.serialTasks);
          };
        };
      };
    })
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
            deps = ifNotEmpty cfg.check.dependsOn;
            cmds = ifNotEmpty (tasksToCmds cfg.check.serialTasks);
          };
        };
      };
    })
    (lib.mkIf cfg.test.enable {
      tools.go-task = {
        taskfile.tasks = {
          test = {
            desc = "Run all tests";
            deps = ifNotEmpty cfg.test.dependsOn;
            cmds = ifNotEmpty (tasksToCmds cfg.test.serialTasks);
          };
        };
      };
    })
  ];
}
