# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.cue;
  cueExe = lib.getExe cfg.package;
in
{
  options = {
    tools.cue = {
      enable = lib.mkEnableOption "Enable cue integration";
      package = lib.mkPackageOption toolsPkgs "cue" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.cue = {
            command = cueExe;
            options = [
              "fmt"
              "--files"
            ];
            includes = [
              "*.cue"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:cue" = {
            desc = "Run cue. Additional CLI arguments after `--` are forwarded to cue";
            cmds = [ "${cueExe} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
