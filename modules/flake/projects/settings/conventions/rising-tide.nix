# rising-tide flake context
{ lib, ... }:
# project settings context
{ config, project, ... }:
let
  rootProjectConfig = {
    tools = {
      nixfmt-rfc-style.enable = true;
      lefthook = {
        enable = true;
        config = {
          assert_lefthook_installed = true;
          pre-commit = {
            commands = {
              check = {
                run = "${lib.getExe' config.tools.go-task.package "task"} check";
                stage_fixed = true;
              };
            };
          };
        };
      };
      shellcheck.enable = true;
      shfmt.enable = true;
      vscode.enable = true;
    };
  };
  allProjectsConfig = {
    tools = {
      go-task.enable = true;
      mypy.config = {
        strict = true;
        warn_return_any = true;
        warn_unused_configs = true;
        disallow_untyped_defs = true;
        disallow_untyped_calls = true;
        disallow_incomplete_defs = true;
        overrides = [
          {
            module = "tests.*";
            disallow_untyped_defs = false;
            disallow_untyped_calls = false;
            disallow_incomplete_defs = false;
          }
        ];
      };
      ruff.config = {
        # A longer default line length. 79/80 is too short.
        line-length = 120;
        lint = {
          extend-select = [
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
          ];
        };
        lint.extend-per-file-ignores = {
          # Ignore PLR2004 (magic constants) in tests
          "tests/**" = [ "PLR2004" ];
        };
      };
      shfmt.styleOptions = [
        "--simplify"
        "--indent"
        "2"
        "--case-indent"
        "--binary-next-line"
      ];
    };
  };
  pythonProjectConfig = {
    tools = {
      mypy.enable = true;
      ruff.enable = true;
      uv.enable = true;
    };
  };
in
{
  config = lib.mkMerge [
    allProjectsConfig
    (lib.mkIf (project.relativePaths.toRoot == "./.") rootProjectConfig)
    (lib.mkIf (config.python.enable) pythonProjectConfig)
  ];
}
