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
        description = "Tasks that are triggered by running a task of the same name in the parent project";
        type = types.listOf types.str;
        default = builtins.filter (taskName: !(lib.hasInfix ":" taskName)) (
          builtins.attrNames (cfg.taskfile.tasks or { })
        );
        defaultText = lib.literalMD "All tasks that do not contain a colon in their name";
      };
      configFile = lib.mkOption {
        description = "The go-task configuration file to use";
        type = types.pathInStore;
        default =
          inputs.nixago.engines.${system}.cue
            {
              files = [ ./taskfile.cue ];
            }
            {
              data = cfg.taskfile;
              output = "taskfile.yml";
              format = "yaml";
            };
      };
    };
  };

  config =
    let
      enabledSubprojects = lib.filterAttrs (_name: enabledIn) config.subprojects;
    in
    lib.mkIf cfg.enable {
      mkShell.nativeBuildInputs = [
        (toolsPkgs.makeSetupHook {
          name = "go-task-setup-hook.sh";
          propagatedBuildInputs = [ cfg.package ];
        } ./go-task-setup-hook.sh)
      ];
      tools = {
        # The default output format of interleaved does not do line-buffering. As a result,
        # interleaved terminal codes (e.g. colours) can get mixed up with the output of other
        # terminal codes confusing the terminal.
        go-task.taskfile = {
          output = lib.mkDefault "prefixed";
          includes = lib.mkMerge (
            lib.mapAttrsToList (name: subprojectConfig: {
              ${name} = {
                taskfile = subprojectConfig.relativePaths.toParentProject;
                dir = subprojectConfig.relativePaths.toParentProject;
              };
            }) enabledSubprojects
          );
          tasks = lib.mkMerge (
            (lib.mapAttrsToList (
              _name: subprojectConfig:
              lib.genAttrs (getCfg subprojectConfig).inheritedTasks (taskName: {
                deps = [ "${subprojectConfig.name}:${taskName}" ];
              })
            ) enabledSubprojects)
            ++ [
              {
                "nix-build:*" = {
                  desc = "Build a package with `nix build`";
                  vars.PACKAGE = "{{index .MATCH 0}}";
                  label = "nix-build:{{.PACKAGE}}";
                  prefix = "nix-build:{{.PACKAGE}}";
                  cmds = [ "nix build --show-trace --log-lines 500 .?submodules=1#{{.PACKAGE}}" ];
                };
                check.cmds = [
                  { task = "check:_serial"; }
                  { task = "check:_concurrent"; }
                ];
                "check:_serial" = {
                  internal = true;
                };
                "check:_concurrent" = {
                  internal = true;
                };
              }
            ]
          );
        };
        nixago.requests = lib.mkIf (cfg.taskfile != { }) [
          {
            data = cfg.configFile;
            output = "taskfile.yml";
          }
        ];
        vscode.recommendedExtensions = lib.mkIf config.isRootProject {
          "task.vscode-task" = true;
        };
      };
    };
}
