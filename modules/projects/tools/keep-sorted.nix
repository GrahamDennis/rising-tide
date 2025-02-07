# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.keep-sorted;
  keepSortedExe = lib.getExe cfg.package;
in
{
  options = {
    tools.keep-sorted = {
      enable = lib.mkEnableOption "Enable keep-sorted integration";
      package = lib.mkPackageOption toolsPkgs "keep-sorted" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.keep-sorted = {
            command = keepSortedExe;
            includes = [ "*" ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:keep-sorted" = {
            desc = "Run keep-sorted. Additional CLI arguments after `--` are forwarded to keep-sorted";
            cmds = [ "${keepSortedExe} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
