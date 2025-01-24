# rising-tide flake context
{
  lib,
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
  cfg = config.tools.clang-format;
  settingsFormat = toolsPkgs.formats.yaml { };
  clangFormatExe = lib.getExe' cfg.package "clang-format";
in
{
  options = {
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
      configFile = lib.mkOption {
        description = "The clang-format configuration file to use";
        type = types.pathInStore;
        default =
          inputs.nixago.engines.${system}.cue
            {
              flags = {
                expression = "rendered";
                out = "text";
              };

              files = [ ./clang-format.cue ];
            }
            {
              data = cfg.config;
              output = "clang-format.yaml";
              format = "yaml";
            };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      nixago.requests = [
        {
          data = cfg.configFile;
          output = ".clang-format";
        }
      ];
      treefmt = {
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
      go-task = {
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
