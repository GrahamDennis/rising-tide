# rising-tide flake context
{ lib, ... }:
# project tools context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.nixfmt-rfc-style;
  nixfmtExe = lib.getExe cfg.package;
in
{
  options.tools.nixfmt-rfc-style = {
    enable = lib.mkEnableOption "Enable nixfmt-rfc-style integration";
    package = lib.mkPackageOption toolsPkgs "nixfmt-rfc-style" { pkgsText = "toolsPkgs"; };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
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
      vscode.settings = {
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
  };
}
