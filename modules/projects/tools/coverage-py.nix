# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  getCfg = projectConfig: projectConfig.tools.coverage-py;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
  settingsFormat = toolsPkgs.formats.toml { };
  coverageConfigFile = settingsFormat.generate "coverage.toml" {
    tool.coverage = cfg.config;
  };
in
{
  options = {
    tools.coverage-py = {
      enable = lib.mkEnableOption "Enable coverage-py integration";
      config = lib.mkOption {
        description = ''
          The python coverage TOML configuration file to generate. All configuration here is nested under the `tool.coverage` key
          in the generated file.

          Refer to the [coverage documentation](https://coverage.readthedocs.io/en/7.6.10/config.html#toml-syntax).
        '';
        type = settingsFormat.type;
        default = { };
        example = {
          report.fail_under = 100;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      mkShell.nativeBuildInputs = [ config.languages.python.pythonPackages.pytest-cov ];
      tasks.test.serialTasks = lib.mkAfter [ "test:coverage-report" ];
      tools = {
        pytest.config = {
          addopts = [
            "--cov"
            "--cov-config=${toString coverageConfigFile}"
            "--cov-report="
            # Don't complain about total coverage during test execution, only during coverage report
            "--cov-fail-under=0"
          ];
        };

        go-task = {
          enable = true;
          taskfile = {
            tasks = {
              "test:pytest" = {
                env.COVERAGE_FILE = ".coverage.pytest";
              };
              "test:coverage-report" = {
                desc = "Generate a coverage report";
                cmds = [
                  "coverage combine"
                  "coverage report"
                ];
                env = {
                  COVERAGE_RCFILE = builtins.toString coverageConfigFile;
                };
              };
              "tool:coverage" = {
                desc = "Run python coverage tool.";
                cmds = [ "coverage {{.CLI_ARGS}}" ];
                env = {
                  COVERAGE_RCFILE = builtins.toString coverageConfigFile;
                };
              };
            };
          };
        };
      };
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.gitignore = {
        enable = true;
        rules = ''
          .coverage*
        '';
      };
    })
  ];
}
