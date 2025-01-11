# rising-tide flake context
{ lib, flake-parts-lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.nixfmt-rfc-style;
  nixfmtExe = lib.getExe cfg.package;
in
{
  options.settings = mkSubmoduleOptions {
    tools.nixfmt-rfc-style = {
      enable = lib.mkEnableOption "Enable nixfmt-rfc-style integration";
      package = lib.mkPackageOption toolsPkgs "nixfmt-rfc-style" { pkgsText = "toolsPkgs"; };
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
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
        go-task = {
          enable = true;
          taskfile.tasks = {
            "tool:nixfmt-rfc-style" = {
              desc = "Run nixfmt-rfc-style. Additional CLI arguments after `--` are forwarded";
              cmds = [ "${nixfmtExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
      rootProjectSettings.vscode.settings = {
        "nix.formatterPath" = nixfmtExe;
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {
              "command" = [ nixfmtExe ];
            };
          };
        };
      };
    };
}
