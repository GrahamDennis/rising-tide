# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  getCfg = projectConfig: projectConfig.tools.nil;
  cfg = getCfg config;
  nilExe = lib.getExe cfg.package;
in
{
  options = {
    tools.nil = {
      enable = lib.mkEnableOption "Enable nil integration";
      package = lib.mkPackageOption toolsPkgs "nil" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        go-task = {
          enable = true;
          taskfile.tasks = {
            "tool:nil" = {
              desc = "Run nil. Additional CLI arguments after `--` are forwarded";
              cmds = [ "${nilExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    })

    (lib.mkIf config.isRootProject {
      tools.vscode.settings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = nilExe;
      };
    })
  ];
}
