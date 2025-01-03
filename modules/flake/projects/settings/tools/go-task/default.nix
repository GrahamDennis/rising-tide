# rising-tide context
{
  lib,
  inputs,
  ...
}:
# project tools context
{
  config,
  toolsPkgs,
  system,
  project,
  ...
}: let
  inherit (lib) types;
  cfg = config.tools.go-task;
  yamlFormat = toolsPkgs.formats.yaml {};
  wrappedPackage = toolsPkgs.writeScriptBin "task" ''
    # Temporary workaround until https://github.com/go-task/task/pull/1974 gets merged
    exec ${cfg.package}/bin/task --concurrency 1 "$@"
  '';
in {
  options.tools.go-task = {
    enable = lib.mkEnableOption "Enable go-task integration";
    package = lib.mkPackageOption toolsPkgs "go-task" {};
    taskfile = lib.mkOption {
      type = yamlFormat.type;
      default = {};
    };
    inheritedTasks = lib.mkOption {
      type = types.listOf types.str;
      default = builtins.attrNames (cfg.taskfile.tasks or {});
    };
  };

  config = lib.mkIf cfg.enable {
    # The default output format of interleaved does not do line-buffering. As a result,
    # interleaved terminal codes (e.g. colours) can get mixed up with the output of other
    # terminal codes confusing the terminal.
    tools = {
      go-task.taskfile.output = lib.mkDefault "prefixed";
      all = [
        (toolsPkgs.makeSetupHook {
            name = "go-task-setup-hook.sh";
            propagatedBuildInputs = [wrappedPackage];
          }
          ./go-task-setup-hook.sh)
      ];
      nixago.requests = lib.mkIf (cfg.taskfile != {}) [
        {
          data = cfg.taskfile;
          output = "taskfile.yml";
          format = "yaml";
          engine = inputs.nixago.engines.${system}.cue {
            files = [./taskfile.cue];
          };
        }
      ];
    };

    parentProjectSettings = {
      tools.go-task.taskfile = {
        includes.${project.name} = {
          taskfile = project.relativePaths.toParentProject;
          dir = project.relativePaths.toParentProject;
        };
        tasks = lib.genAttrs cfg.inheritedTasks (taskName: {deps = ["${project.name}:${taskName}"];});
      };
    };
  };
}
