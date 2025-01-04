# rising-tide flake context
{ lib, ... }:
# project settings context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.ruff;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "ruff.toml" cfg.config;
  ruffExe = lib.getExe cfg.package;
in
{
  options.tools.ruff = {
    enable = lib.mkEnableOption "Enable ruff integration";
    package = lib.mkPackageOption toolsPkgs "ruff" { pkgsText = "toolsPkgs"; };
    config = lib.mkOption {
      description = ''
        The ruff TOML configuration file (`ruff.toml`) to generate.

        Refer to the [ruff documentation](https://docs.astral.sh/ruff/settings/#__tabbed_1_2).'';
      type = settingsFormat.type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.ruff-lint = {
            command = ruffExe;
            options = [
              "--config"
              (toString configFile)
              "check"
              "--fix"
            ];
            includes = [
              "*.py"
              "*.pyi"
            ];
          };
          formatter.ruff-format = {
            command = ruffExe;
            options = [
              "--config"
              (toString configFile)
              "format"
            ];
            includes = [
              "*.py"
              "*.pyi"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:ruff" = {
            desc = "Run ruff. Additional CLI arguments after `--` are forwarded to ruff";
            cmds = [ "${ruffExe} --config ${toString configFile} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
