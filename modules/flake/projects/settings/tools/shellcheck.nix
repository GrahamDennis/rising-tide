# rising-tide flake context
{ lib, ... }:
# project settings context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.shellcheck;
  settingsFormat = toolsPkgs.formats.keyValue { };
  configFile = settingsFormat.generate "shellcheckrc" cfg.config;
  shellCheckExe = lib.getExe cfg.package;
in
{
  options.tools.shellcheck = {
    enable = lib.mkEnableOption "Enable shellcheck integration";
    package = lib.mkPackageOption toolsPkgs "shellcheck" { pkgsText = "toolsPkgs"; };
    config = lib.mkOption {
      type = settingsFormat.type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.shellcheck = {
            command = shellCheckExe;
            options = [
              "--rcfile"
              (toString configFile)
            ];
            includes = [
              "*.sh"
              "*.bash"
              "*.bats"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:shellcheck" = {
            desc = "Run shellcheck. Additional CLI arguments after `--` are forwarded to shellcheck";
            cmds = [ "${shellCheckExe} --rcfile ${toString configFile} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
