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
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      mkShell.nativeBuildInputs = [ config.languages.python.pythonPackages.pytest ];
      tasks.test.dependsOn = [ "test:pytest" ];

      tools = {
        pytest.config = {
          addopts = [
            "--showlocals"
            "--maxfail=1"
          ];
        };
        go-task = {
          enable = true;
          taskfile = {
            tasks =
              let
                callPytest = args: "pytest --config-file=${toString configFile} --rootdir=. ${args}";
              in

              {
                "test:pytest" = {
                  desc = "Run pytest";
                  # Only run pytest if there is a test directory
                  cmds = [
                    "mkdir -p $FLAKE_ROOT/test_results/pytest"
                    # Suppress Ctrl-C to pytest because when run in parallel and a test fails, pytest creates sprurious errors from
                    # the cancelled tests. This is a workaround to prevent that.
                    "nohup ${(callPytest "--junit-xml=$FLAKE_ROOT/test_results/pytest/${config.name}.xml ${builtins.concatStringsSep " " config.languages.python.testRoots}")}"
                  ];
                };
                "tool:pytest" = {
                  desc = "Run pytest. Additional CLI arguments after `--` are forwarded to pytest";
                  cmds = [ (callPytest "{{.CLI_ARGS}}") ];
                };
              };
          };
        };
        vscode = {
          enable = true;
          settings = {
            "python.testing.pytestEnabled" = true;
            "python.testing.unittestEnabled" = false;
            "python.testing.pytestArgs" = [
              "--config-file=${toString configFile}"
            ] ++ (config.languages.python.testRoots);
          };
        };
      };
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.gitignore = {
        enable = true;
        rules = ''
          .pytest_cache/
          /test_results/
        '';
      };
    })
  ];
}
