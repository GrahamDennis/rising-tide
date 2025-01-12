# rising-tide flake context
{ injector, ... }:
# project context
{
  config,
  ...
}:
{
  imports = injector.injectModules [
    ./cpp.nix
    ./python.nix
    ./root-project.nix
  ];
  config = {
    settings.tools = {
      clang-format.config = {
        header = {
          BasedOnStyle = "Google";
          ColumnLimit = 120;
        };
      };
      cmake-format.config = {
        format.line_width = 120;
      };
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
      pytest = {
        config = {
          markers = [ "integration" ];
        };
        coverage.config = {
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
      shfmt.printerFlags = [
        "--simplify"
        "--indent"
        "2"
        "--case-indent"
        "--binary-next-line"
      ];
    };
  };
}
