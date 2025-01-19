# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  getCfg = projectConfig: projectConfig.settings.tools.nixfmt-rfc-style;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
  cfg = getCfg config;
  nixfmtExe = lib.getExe cfg.package;
in
{
  options.settings = {
    tools.nixfmt-rfc-style = {
      enable = lib.mkEnableOption "Enable nixfmt-rfc-style integration";
      package = lib.mkPackageOption toolsPkgs "nixfmt-rfc-style" { pkgsText = "toolsPkgs"; };
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    lib.mkMerge [
      {
        settings.tools = {
          treefmt = ifEnabled {
            enable = true;
            config = {
              formatter.nixfmt-rfc-style = {
                command = nixfmtExe;
                includes = [ "*.nix" ];
              };
            };
          };
          go-task = ifEnabled {
            enable = true;
            taskfile.tasks = {
              "tool:nixfmt-rfc-style" = {
                desc = "Run nixfmt-rfc-style. Additional CLI arguments after `--` are forwarded";
                cmds = [ "${nixfmtExe} {{.CLI_ARGS}}" ];
              };
            };
          };
        };
      }

      (lib.mkIf config.isRootProject {
        settings.tools.vscode.settings = lib.mkIf (builtins.any enabledIn config.allProjectsList) {
          # FIXME: This uses the root project's nixfmt not what has been configured on child projects
          "nix.formatterPath" = nixfmtExe;
          "nix.serverSettings" = {
            "nil" = {
              "formatting" = {
                "command" = [ nixfmtExe ];
              };
            };
          };
        };
      })
    ];
}
