# rising-tide context
{
  lib,
  inputs,
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
  getCfg = projectConfig: projectConfig.tools.go-task;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
  settingsFormat = toolsPkgs.formats.yaml { };
  wrappedPackage = toolsPkgs.writeScriptBin "task" ''
    # Temporary workaround until go-task >3.40.1 is available in nixpkgs
    exec ${cfg.package}/bin/task --concurrency 1 "$@"
  '';
in
{
  options = {
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
      enabledSubprojects = lib.filterAttrs (_name: enabledIn) config.subprojects;
    in
    {
      allTools = ifEnabled [
        (toolsPkgs.makeSetupHook {
          name = "go-task-setup-hook.sh";
          propagatedBuildInputs = [ wrappedPackage ];
        } ./go-task-setup-hook.sh)
      ];
      tools = {
        # The default output format of interleaved does not do line-buffering. As a result,
        # interleaved terminal codes (e.g. colours) can get mixed up with the output of other
        # terminal codes confusing the terminal.
        go-task.taskfile = {
          output = ifEnabled (lib.mkDefault "prefixed");
          includes = lib.mkMerge (
            lib.mapAttrsToList (name: subprojectConfig: {
              "${name}" = {
                taskfile = subprojectConfig.relativePaths.toParentProject;
                dir = subprojectConfig.relativePaths.toParentProject;
              };
            }) enabledSubprojects
          );
          tasks = lib.mkMerge (
            lib.mapAttrsToList (
              _name: subprojectConfig:
              lib.genAttrs (getCfg subprojectConfig).inheritedTasks (taskName: {
                deps = [ "${subprojectConfig.name}:${taskName}" ];
              })
            ) enabledSubprojects
          );
        };
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
    };
}
