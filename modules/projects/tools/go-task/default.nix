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
  enabledIn = projectConfig: projectConfig.enable && (getCfg projectConfig).enable;
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
        go-task.taskfile =
          let
            colourEscape = "";
          in
          {
            # The default output format of interleaved does not do line-buffering. As a result,
            # interleaved terminal codes (e.g. colours) can get mixed up with the output of other
            # terminal codes confusing the terminal.
            vars = {
              _GROUP_COLOURS = builtins.concatStringsSep "," [
                "${colourEscape}[1;33m" # bold yellow
                "${colourEscape}[1;34m" # bold blue
                "${colourEscape}[1;35m" # bold magenta
                "${colourEscape}[1;32m" # bold green
                "${colourEscape}[1;36m" # bold cyan
                "${colourEscape}[1;93m" # bold high-intensity yellow
                "${colourEscape}[1;94m" # bold high-intensity blue
                "${colourEscape}[1;95m" # bold high-intensity magenta
                "${colourEscape}[1;92m" # bold high-intensity green
                "${colourEscape}[1;96m" # bold high-intensity cyan
              ];
            };
            output = lib.mkDefault {
              group =
                let
                  setColour = ''{{$colours := splitList "," ._GROUP_COLOURS }}{{ index $colours (mod (adler32sum .ALIAS) (len $colours)) }}'';
                  resetColour = "${colourEscape}[0m";
                in
                {
                  begin = "${setColour}[BEGIN] {{.ALIAS}}${resetColour}";
                  end = "${setColour}[END]   {{.ALIAS}}${resetColour}";
                };
            };
            includes = lib.mkMerge (
              lib.mapAttrsToList (name: subprojectConfig: {
                ${name} = {
                  taskfile = subprojectConfig.relativePaths.fromParentProject;
                  dir = subprojectConfig.relativePaths.fromParentProject;
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
