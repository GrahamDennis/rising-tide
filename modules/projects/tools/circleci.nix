# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.circleci;
  circleciExe = lib.getExe cfg.package;
in
{
  options = {
    tools.circleci = {
      enable = lib.mkEnableOption "Enable circleci integration";
      package = lib.mkPackageOption toolsPkgs "circleci-cli" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.circleci = {
            command = circleciExe;
            options = [
              "--skip-update-check"
              "config"
              "validate"
            ];
            includes = [
              ".circleci/config.yml"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:circleci" = {
            desc = "Run circleci. Additional CLI arguments after `--` are forwarded to cue";
            cmds = [ "${circleciExe} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
