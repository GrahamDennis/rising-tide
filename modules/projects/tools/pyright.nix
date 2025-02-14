# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  getCfg = projectConfig: projectConfig.tools.pyright;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
  settingsFormat = toolsPkgs.formats.json { };
  pyrightExe = lib.getExe cfg.package;
in
{
  options = {
    tools.pyright = {
      enable = lib.mkEnableOption "Enable pyright integration";
      package = lib.mkPackageOption toolsPkgs "pyright" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The pyright JSON config file to generate.
          Refer to the [pyright documentation](https://microsoft.github.io/pyright/#/configuration).
        '';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "pyrightconfig.json" cfg.config;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tasks.check.dependsOn = [ "check:pyright" ];
      tools = {
        go-task = {
          enable = true;
          taskfile.tasks =
            let
              callPyright = args: "${pyrightExe} --project=${toString cfg.configFile} ${args}";
            in
            {
              "check:pyright" = {
                desc = "Run pyright type checker";
                cmds = [
                  (callPyright (
                    builtins.concatStringsSep " " (
                      config.languages.python.sourceRoots ++ config.languages.python.testRoots
                    )
                  ))
                ];
              };
              "tool:pyright" = {
                desc = "Run pyright. Additional CLI arguments after `--` are forwarded to pyright";
                cmds = [ (callPyright "{{.CLI_ARGS}}") ];
              };
            };
        };
      };
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools = {
        vscode = {
          settings = {
            "python.analysis.languageServerMode" = "full";
            "python.analysis.typeCheckingMode" = "standard";
          };
          recommendedExtensions."ms-python.vscode-pylance".enable = true;
        };
      };
    })
  ];
}
