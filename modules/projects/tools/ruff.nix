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
            formatter.ruff-lint-fix-only = lib.mkIf cfg.lint.enable {
              command = ruffExe;
              options = [
                "check"
                "--fix-only"
              ];
              includes = [
                "*.py"
                "*.pyi"
              ];
              # Ensure linters that don't format run first
              priority = -10;
            };
            formatter.ruff-lint = lib.mkIf cfg.lint.enable {
              command = ruffExe;
              options = [
                "check"
              ];
              includes = [
                "*.py"
                "*.pyi"
              ];
              # Ensure read-only linters run last
              priority = 10;
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
        vscode = {
          recommendedExtensions = {
            "charliermarsh.ruff".enable = true;
          };
          settings = {
            "ruff.path" = [ ruffExe ];
          };
        };
      };
    })

    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allEnabledProjectsList)) {
      tools.gitignore = {
        enable = true;
        rules = ''
          .ruff_cache/
        '';
      };
      tools.jetbrains = {
        requiredPlugins."com.koxudaxi.ruff" = true;
        projectSettings."ruff.xml" = {
          components.RuffConfigService.options = {
            globalRuffExecutablePath = lib.getExe config.tools.ruff.package;
            useRuffServer = "true";
            useRuffFormat = "true";
          };
        };
      };
    })
  ];
}
