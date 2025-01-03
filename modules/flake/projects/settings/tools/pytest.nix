# rising-tide flake context
{
  lib,
  inputs,
  ...
}:
# project settings context
{
  config,
  toolsPkgs,
  system,
  ...
}:
let
  cfg = config.tools.pytest;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "pytest.toml" {
    tool.pytest.ini_options = cfg.config;
  };
  coverageConfigFile = settingsFormat.generate "coverage.toml" {
    tool.coverage = cfg.coverage.config;
  };
in
{
  options.tools.pytest = {
    enable = lib.mkEnableOption "Enable pytest integration";
    coverage = {
      enable = lib.mkEnableOption "Enable pytest-cov integration";
      config = lib.mkOption {
        type = settingsFormat.type;
        default = { };
      };
    };
    config = lib.mkOption {
      type = settingsFormat.type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      pytest.config = lib.mkMerge [
        {
          addopts = [
            "--showlocals"
            "--maxfail=1"
          ];
        }
        (lib.mkIf cfg.coverage.enable {
          addopts = [
            "--cov"
            "--cov-config=${toString coverageConfigFile}"
          ];
        })
      ];

      go-task = {
        enable = true;
        taskfile = {
          tasks =
            let
              callPytest = args: "pytest --config-file=${toString configFile} --rootdir=. ${args}";
            in
            lib.mkMerge [
              {
                test.deps = [ "test:pytest" ];
                "test:pytest" = {
                  desc = "Run pytest";
                  cmds = [ (callPytest "--junitxml=./build/test.xml ./tests") ];
                };
                "tool:pytest" = {
                  desc = "Run pytest. Additional CLI arguments after `--` are forwarded to pytest";
                  cmds = [ (callPytest "{{.CLI_ARGS}}") ];
                };
              }
              (lib.mkIf cfg.coverage.enable {
                "tool:coverage" = {
                  desc = "Run python coverage tool.";
                  cmds = [ "coverage {{.CLI_ARGS}}" ];
                  env = {
                    COVERAGE_RCFILE = builtins.toString coverageConfigFile;
                  };
                };
              })
            ];
        };
      };
    };
  };
}
