# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.settings.tools.clang-tidy;
  settingsFormat = toolsPkgs.formats.yaml { };
  clangTidyExe = lib.getExe' cfg.package "clang-tidy";
in
{
  options.settings = {
    tools.clang-tidy = {
      enable = lib.mkEnableOption "Enable clang-tidy integration";
      package = lib.mkPackageOption toolsPkgs "clang-tools" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The clang-tidy YAML file to generate.
          Refer to the [clang-tide documentation](https://clang.llvm.org/extra/clang-tidy/).
        '';
        type = settingsFormat.type;
        default = { };
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
            output = ".clang-tidy";
            format = "yaml";
          }
        ]);
        treefmt = ifEnabled {
          enable = true;
          config = {
            formatter.clang-tidy = {
              command = clangTidyExe;
              options = [
                "-p"
                "build"
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
            "tool:clang-tidy" = {
              desc = "Run clang-tidy. Additional CLI arguments after `--` are forwarded to clang-tidy";
              cmds = [ "${clangTidyExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    };
}
