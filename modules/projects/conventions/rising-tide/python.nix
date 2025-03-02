# rising-tide flake context
{ lib, injector, ... }:
# project context
{
  config,
  ...
}:
let
  cfg = config.conventions.risingTide.python;
  getLangCfg = projectConfig: projectConfig.languages.python;
  pythonEnabledIn = projectConfig: (getLangCfg projectConfig).enable;
in
{
  imports = injector.injectModules [ ./common.nix ];
  options.conventions.risingTide.python = {
    enable = lib.mkEnableOption "Enable rising-tide Python conventions";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Python tool configurations
      {
        conventions.risingTide.common.enable = true;
        tools = {
          mypy = {
            config = {
              pretty = true;
              strict = true;
              show_error_codes = true;
              warn_unreachable = true;
              local_partial_types = true;
              warn_return_any = true;
              warn_unused_configs = true;
              disallow_untyped_defs = true;
              disallow_untyped_calls = true;
              disallow_incomplete_defs = true;
            };
            perModuleOverrides."tests.*" = {
              disallow_untyped_defs = false;
              disallow_untyped_calls = false;
              disallow_incomplete_defs = false;
            };
            # FIXME: Add grpc-stubs
            perModuleOverrides."grpc.*" = {
              follow_untyped_imports = true;
            };
          };
          pytest = {
            config = {
              markers = [ "integration" ];
            };
          };
          coverage-py.config = {
            run.branch = true;
            run.source = [ "src/" ];
            report = {
              exclude_also = [
                # don't complain about conditional type checking imports
                "if TYPE_CHECKING:"
                # Don't complain about abstract methods, they aren't run:
                "@(abc\\.)?abstractmethod"
                # Don't complain about assert_never calls, as they aren't run:
                "assert_never\\("
              ];
              show_missing = true;
              skip_covered = true;
              skip_empty = true;
            };
          };
          ruff.config = {
            # A longer default line length. 79/80 is too short.
            line-length = 120;
            lint = {
              extend-select = [
                # keep-sorted start
                "C4"
                "E"
                "F"
                "G"
                "I"
                "N"
                "NPY"
                "PD"
                "PL"
                "PT"
                "RUF"
                "SIM"
                "TCH"
                "W"
                # keep-sorted end
              ];
            };
            lint.extend-per-file-ignores = {
              # Ignore PLR2004 (magic constants) in tests
              "tests/**" = [ "PLR2004" ];
            };
          };
        };
      }
      # Enable Python tools in Python projects
      (lib.mkIf (pythonEnabledIn config) {
        tools = {
          # keep-sorted start block=yes
          coverage-py.enable = (getLangCfg config).testRoots != [ ];
          gitignore = {
            enable = true;
            rules = ''
              # Python-generated files
              __pycache__/
              *.py[oc]
              build/
              dist/
              wheels/
              *.egg-info
            '';
          };
          mypy.enable = true;
          pyright.enable = true;
          pytest.enable = (getLangCfg config).testRoots != [ ];
          ruff.format.enable = true;
          ruff.lint.enable = true;
          uv.enable = true;
          # keep-sorted end
        };
      })
    ]
  );
}
