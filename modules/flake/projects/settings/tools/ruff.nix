# rising-tide flake context
{ lib, flake-parts-lib, ... }:
# project settings context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.ruff;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "ruff.toml" cfg.config;
  ruffExe = lib.getExe cfg.package;
in
{
  options.settings = mkSubmoduleOptions {
    tools.ruff = {
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
        go-task = ifEnabled {
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
