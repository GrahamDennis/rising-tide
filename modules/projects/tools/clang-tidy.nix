# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.clang-tidy;
  settingsFormat = toolsPkgs.formats.yaml { };
  clangTidyExe = lib.getExe' cfg.package "clang-tidy";
in
{
  options = {
    tools.clang-tidy = {
      enable = lib.mkEnableOption "Enable clang-tidy integration";
      package = lib.mkPackageOption toolsPkgs "clang-tools" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The clang-tidy YAML file to generate.
          Refer to the [clang-tidy documentation](https://clang.llvm.org/extra/clang-tidy/).
        '';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "clang-tidy.yaml" cfg.config;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      nixago.requests = [
        {
          data = cfg.configFile;
          output = ".clang-tidy";
        }
      ];
      treefmt = {
        enable = true;
        config = {
          formatter.clang-tidy = {
            command = clangTidyExe;
            options = [
              "--fix"
              "--format-style=file"
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
      go-task = {
        enable = true;
        taskfile.tasks = {
          "check:treefmt" = {
            # cmake:configure will create build/compile_commands.json
            deps = [ "cmake:configure" ];
            # build/compile_commands.json is required for clang-tidy
            preconditions = [ "test -f build/compile_commands.json" ];
          };
          "check:clang-tidy" = {
            # cmake:configure will create build/compile_commands.json
            deps = [ "cmake:configure" ];
            # build/compile_commands.json is required for clang-tidy
            preconditions = [ "test -f build/compile_commands.json" ];

          };
          "tool:clang-tidy" = {
            desc = "Run clang-tidy. Additional CLI arguments after `--` are forwarded to clang-tidy";
            cmds = [ "${clangTidyExe} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
