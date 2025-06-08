# rising-tide context
{
  lib,
  inputs,
  self,
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
  enabledIn = projectConfig: projectConfig.enable && (getCfg projectConfig).enable;
  settingsFormat = toolsPkgs.formats.yaml { };
in
{
  options = {
    tools.go-task = {
      enable = lib.mkEnableOption "Enable go-task integration";
      # Temporarily using a patched version of go-task to improve error reporting in tasks
      # package = lib.mkPackageOption toolsPkgs "go-task" { pkgsText = "toolsPkgs"; };
      package = lib.mkPackageOption (self.packages.${toolsPkgs.system}) "go-task-patched" {
        pkgsText = "risingTide.packages";
      };
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
        go-task.taskfile =
          let
            colourEscape = "";
            groupedOutputConfig = {
              version = "3";
              vars._GROUP_COLOURS = [
                # Don't use red as it looks like an error
                # "${colourEscape}[1;31m" # bold red
                "${colourEscape}[1;32m" # bold green
                "${colourEscape}[1;33m" # bold yellow
                "${colourEscape}[1;34m" # bold blue
                "${colourEscape}[1;35m" # bold magenta
                "${colourEscape}[1;36m" # bold cyan
                "${colourEscape}[1;37m" # bold white
                # Don't use red as it looks like an error
                # "${colourEscape}[1;91m" # bold high-intensity red
                "${colourEscape}[1;92m" # bold high-intensity green
                "${colourEscape}[1;93m" # bold high-intensity yellow
                "${colourEscape}[1;94m" # bold high-intensity blue
                "${colourEscape}[1;95m" # bold high-intensity magenta
                "${colourEscape}[1;96m" # bold high-intensity cyan
                "${colourEscape}[1;97m" # bold high-intensity white
              ];
              output.group =
                let
                  setColour = ''{{ index ._GROUP_COLOURS (mod (adler32sum .ALIAS) (len ._GROUP_COLOURS)) }}'';
                  resetColour = "${colourEscape}[0m";
                in
                {
                  begin = "${setColour}[BEGIN] {{.ALIAS}}${resetColour}";
                  end = "${setColour}[END]   {{.ALIAS}}${resetColour}";
                };
            };
            prefixedOutputConfig = {
              version = "3";
              output = "prefixed";
            };
            groupOutputTaskfile = settingsFormat.generate "taskfile.group.yaml" groupedOutputConfig;
            prefixedOutputTaskfile = settingsFormat.generate "taskfile.prefixed.yaml" prefixedOutputConfig;
          in
          {
            includes = lib.mkMerge (
              (lib.mapAttrsToList (name: subprojectConfig: {
                ${name} = {
                  taskfile = subprojectConfig.relativePaths.fromParentProject;
                  dir = subprojectConfig.relativePaths.fromParentProject;
                };
              }) enabledSubprojects)
              ++ [
                {
                  _output = {
                    internal = true;
                    taskfile = "{{if .CI}}${groupOutputTaskfile}{{else}}${prefixedOutputTaskfile}{{end}}";
                  };
                }
              ]
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
          "task.vscode-task".enable = true;
        };
      };
    };
}
