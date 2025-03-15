# rising-tide flake context
{
  lib,
  risingTideLib,
  injector,
  ...
}:
# project context
{
  config,
  ...
}:
let
  cfg = config.tasks;
  tasksToCmds = builtins.map (name: {
    task = name;
  });
  ifNotEmpty = tasks: lib.mkIf (tasks != [ ]) tasks;
in
{
  imports = injector.injectModules [
    # keep-sorted start
    ./ci/check-derivation-unchanged.nix
    ./ci/check-not-dirty.nix
    # keep-sorted end
  ];

  options.tasks = lib.genAttrs [
    "build"
    "ci"
    "check"
    "test"
  ] risingTideLib.project.mkLifecycleTaskOption;
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
    (lib.mkIf cfg.ci.enable {
      tools.go-task = {
        taskfile.tasks = {
          ci = {
            desc = "Run CI workflow";
            deps = ifNotEmpty cfg.ci.dependsOn;
            cmds = ifNotEmpty (tasksToCmds cfg.ci.serialTasks);
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
