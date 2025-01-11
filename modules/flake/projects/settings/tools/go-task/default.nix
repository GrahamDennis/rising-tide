# rising-tide context
{
  lib,
  inputs,
  flake-parts-lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  system,
  ...
}:
let
  inherit (lib) types;
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.go-task;
  settingsFormat = toolsPkgs.formats.yaml { };
  wrappedPackage = toolsPkgs.writeScriptBin "task" ''
    # Temporary workaround until https://github.com/go-task/task/pull/1974 gets merged
    exec ${cfg.package}/bin/task --concurrency 1 "$@"
  '';
in
{
  options.settings = mkSubmoduleOptions {
    tools.go-task = {
      enable = lib.mkEnableOption "Enable go-task integration";
      package = lib.mkPackageOption toolsPkgs "go-task" { pkgsText = "toolsPkgs"; };
      taskfile = lib.mkOption {
        description = ''
          The go-task taskfile to generate. Refer to the [go-task documentation](https://taskfile.dev/reference/schema).
        '';
        type = settingsFormat.type;
        default = { };
      };
      inheritedTasks = lib.mkOption {
        description = "Tasks to publish to the parent project";
        type = types.listOf types.str;
        default = builtins.filter (taskName: !(lib.hasInfix ":" taskName)) (
          builtins.attrNames (cfg.taskfile.tasks or { })
        );
        defaultText = lib.literalMD "All tasks that do not contain a colon in their name";
      };
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      allTools = ifEnabled [
        (toolsPkgs.makeSetupHook {
          name = "go-task-setup-hook.sh";
          propagatedBuildInputs = [ wrappedPackage ];
        } ./go-task-setup-hook.sh)
      ];
      settings.tools = {
        # The default output format of interleaved does not do line-buffering. As a result,
        # interleaved terminal codes (e.g. colours) can get mixed up with the output of other
        # terminal codes confusing the terminal.
        go-task.taskfile.output = ifEnabled (lib.mkDefault "prefixed");
        nixago.requests = ifEnabled (
          lib.mkIf (cfg.taskfile != { }) [
            {
              data = cfg.taskfile;
              output = "taskfile.yml";
              format = "yaml";
              engine = inputs.nixago.engines.${system}.cue {
                files = [ ./taskfile.cue ];
              };
            }
          ]
        );
      };

      settings.parentProjectSettings = ifEnabled {
        tools.go-task.taskfile = {
          includes.${config.name} = {
            taskfile = config.relativePaths.toParentProject;
            dir = config.relativePaths.toParentProject;
          };
          tasks = lib.genAttrs cfg.inheritedTasks (taskName: {
            deps = [ "${config.name}:${taskName}" ];
          });
        };
      };
    };
}
