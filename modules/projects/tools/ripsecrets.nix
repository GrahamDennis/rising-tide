# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.ripsecrets;
  ripsecretsExe = lib.getExe cfg.package;
in
{
  options = {
    tools.ripsecrets = {
      enable = lib.mkEnableOption "Enable ripsecrets integration";
      package = lib.mkPackageOption toolsPkgs "ripsecrets" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.ripsecrets = {
            command = ripsecretsExe;
            includes = [ "*" ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:ripsecrets" = {
            desc = "Run ripsecrets. Additional CLI arguments after `--` are forwarded to ripsecrets";
            cmds = [ "${ripsecretsExe} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
