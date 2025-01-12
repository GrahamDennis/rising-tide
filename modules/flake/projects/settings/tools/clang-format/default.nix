# rising-tide flake context
{
  lib,
  flake-parts-lib,
  inputs,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  system,
  ...
}:
let
  inherit (lib) types;
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.clang-format;
  settingsFormat = toolsPkgs.formats.yaml { };
  clangFormatExe = lib.getExe' cfg.package "clang-format";
in
{
  options.settings = mkSubmoduleOptions {
    tools.clang-format = {
      enable = lib.mkEnableOption "Enable clang-format integration";
      package = lib.mkPackageOption toolsPkgs "clang-tools" { pkgsText = "toolsPkgs"; };
      config = {
        header = lib.mkOption {
          description = ''
            The header section of the clang-format YAML file to generate.
            Refer to the [clang-format documentation](https://clang.llvm.org/docs/ClangFormatStyleOptions.html).
          '';
          type = settingsFormat.type;
          default = { };
        };
        languages = lib.mkOption {
          type = types.attrsOf (settingsFormat.type);
          description = ''
            Language-specific sections of the clang-format YAML file to generate.
          '';
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
      settings.tools = {
        nixago.requests = ifEnabled ([
          {
            data = cfg.config;
            output = ".clang-format";
            format = "yaml";
            engine = inputs.nixago.engines.${system}.cue {
              flags = {
                expression = "rendered";
                out = "text";
              };

              files = [ ./clang-format.cue ];
            };
          }
        ]);
        treefmt = ifEnabled {
          enable = true;
          config = {
            formatter.clang-format = {
              command = clangFormatExe;
              options = [
                "-i"
              ];
              includes = [
                "*.c"
                "*.cc"
                "*.cpp"
                "*.h"
                "*.hh"
                "*.hpp"
              ];
            };
          };
        };
        go-task = ifEnabled {
          enable = true;
          taskfile.tasks = {
            "tool:clang-format" = {
              desc = "Run clang-format. Additional CLI arguments after `--` are forwarded to clang-format";
              cmds = [ "${clangFormatExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    };
}
