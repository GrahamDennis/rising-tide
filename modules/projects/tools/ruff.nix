# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  enabledIn = projectConfig: projectConfig.tools.ruff.enable;
  cfg = config.tools.ruff;
  settingsFormat = toolsPkgs.formats.toml { };
  ruffExe = lib.getExe cfg.package;
in
{
  options = {
    tools.ruff = {
      enable = lib.mkEnableOption "Enable ruff integration" // {
        default = cfg.lint.enable || cfg.format.enable;
      };
      lint.enable = lib.mkEnableOption "Enable ruff lint";
      format.enable = lib.mkEnableOption "Enable ruff format";
      package = lib.mkPackageOption toolsPkgs "ruff" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The ruff TOML configuration file (`ruff.toml`) to generate.

          Refer to the [ruff documentation](https://docs.astral.sh/ruff/settings/#__tabbed_1_2).'';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "ruff.toml" cfg.config;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        nixago.requests = [
          {
            data = cfg.configFile;
            output = ".ruff.toml";
          }
        ];
        treefmt = {
          enable = true;
          config = {
            formatter.ruff-lint = lib.mkIf cfg.lint.enable {
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
            formatter.ruff-format = lib.mkIf cfg.format.enable {
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
