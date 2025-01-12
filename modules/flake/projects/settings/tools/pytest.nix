# rising-tide flake context
{
  lib,
  flake-parts-lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.pytest;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "pytest.toml" {
    tool.pytest.ini_options = cfg.config;
  };
  coverageConfigFile = settingsFormat.generate "coverage.toml" {
    tool.coverage = cfg.coverage.config;
  };
in
{
  options.settings = mkSubmoduleOptions {
    tools.pytest = {
      enable = lib.mkEnableOption "Enable pytest integration";
      config = lib.mkOption {
        description = ''
          The pytest TOML configuration file to generate. All configuration here is nested under the `tool.pytest.ini_options` key
          in the generated file.

          Refer to the [pytest documentation](https://docs.pytest.org/en/stable/reference/customize.html),
          in particular the [pyproject.toml format documentation](https://docs.pytest.org/en/stable/reference/customize.html#pyproject-toml).
        '';
        type = settingsFormat.type;
        default = { };
      };
      coverage = {
        enable = lib.mkEnableOption "Enable pytest-cov integration";
        config = lib.mkOption {
          description = ''
            The python coverage TOML configuration file to generate. All configuration here is nested under the `tool.coverage` key
            in the generated file.

            Refer to the [coverage documentation](https://coverage.readthedocs.io/en/7.6.10/config.html#toml-syntax).
          '';
          type = settingsFormat.type;
          default = { };
        };
      };
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      settings = {
        tools = {
          pytest.config = ifEnabled (
            lib.mkMerge [
              {
                addopts = [
                  "--showlocals"
                  "--maxfail=1"
                  "--import-mode=importlib"
                ];
              }
              (lib.mkIf cfg.coverage.enable {
                addopts = [
                  "--cov"
                  "--cov-config=${toString coverageConfigFile}"
                ];
              })
            ]
          );

          go-task = ifEnabled {
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
      rootProjectSettings = {
        tools.vscode = {
          settings = ifEnabled {
            "python.testing.pytestEnabled" = true;
            "python.testing.unittestEnabled" = false;
            # This is not quite right because --config-file and --rootdir get added multiple times
            "python.testing.pytestArgs" = [
              "--config-file=${toString configFile}"
              "--rootdir=."
              "${config.relativePaths.toRoot}/tests"
            ];
          };
        };
      };
    };
}
