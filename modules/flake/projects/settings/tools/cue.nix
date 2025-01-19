# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.settings.tools.cue;
  cueExe = lib.getExe cfg.package;
in
{
  options.settings = {
    tools.cue = {
      enable = lib.mkEnableOption "Enable cue integration";
      package = lib.mkPackageOption toolsPkgs "cue" { pkgsText = "toolsPkgs"; };
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
        go-task = ifEnabled {
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
