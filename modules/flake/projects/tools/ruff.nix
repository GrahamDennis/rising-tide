# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  enabledIn = projectConfig: projectConfig.tools.ruff.enable;
  cfg = config.tools.ruff;
  settingsFormat = toolsPkgs.formats.toml { };
  ruffExe = lib.getExe cfg.package;
in
{
  options = {
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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        nixago.requests = [
          {
            data = cfg.config;
            output = ".ruff.toml";
            format = "toml";
          }
        ];
        treefmt = {
          enable = true;
          config = {
            formatter.ruff-lint = {
              command = ruffExe;
              options = [
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
              cmds = [ "${ruffExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    })

    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.vscode = {
        recommendedExtensions = {
          "charliermarsh.ruff" = true;
        };
        settings = {
          "ruff.path" = [ ruffExe ];
        };
      };
    })
  ];
}
