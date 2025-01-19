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
  getCfg = projectConfig: projectConfig.tools.pytest;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "pytest.toml" {
    tool.pytest.ini_options = cfg.config;
  };
  coverageConfigFile = settingsFormat.generate "coverage.toml" {
    tool.coverage = cfg.coverage.config;
  };
in
{
  options = {
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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        pytest.config = (
          lib.mkMerge [
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
          ]
        );

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
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.vscode = {
        settings = {
          "python.testing.pytestEnabled" = true;
          "python.testing.unittestEnabled" = false;
          "python.testing.pytestArgs" =
            [
              "--config-file=${toString configFile}"
              "--override-ini=consider_namespace_packages=true"
              "--override-ini=pythonpath=."
              "--rootdir=."
              # FIXME: this only makes sense if coverage is enabled somewhere
              "--no-cov"
            ]
            ++ (builtins.map (projectConfig: "${projectConfig.relativePaths.toRoot}/tests") (
              builtins.filter enabledIn config.allProjectsList
            ));
        };
      };
    })
  ];
}
