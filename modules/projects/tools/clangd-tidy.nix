# rising-tide flake context
{ lib, self, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.clangd-tidy;
  clangdTidyExe = lib.getExe' cfg.package "clangd-tidy";
in
{
  options = {
    tools.clangd-tidy = {
      enable = lib.mkEnableOption "Enable clangd-tidy integration";
      package = lib.mkPackageOption (self.packages.${toolsPkgs.system}) "clangd-tidy" {
        pkgsText = "risingTide.packages";
      };
      failOnSeverity = lib.mkOption {
        type = types.enum [
          "error"
          "warn"
          "info"
          "hint"
        ];
        default = "error";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.clang-tidy = lib.mkForce {
            command = clangdTidyExe;
            options = [
              "-p"
              "build"
              "--clangd-executable"
              (lib.getExe' config.tools.clangd.package "clangd")
              "--fail-on-severity=${cfg.failOnSeverity}"
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
            # build/compile_commands.json is required for clangd-tidy
            preconditions = [ "test -f build/compile_commands.json" ];
          };
          "tool:clangd-tidy" = {
            desc = "Run clangd-tidy. Additional CLI arguments after `--` are forwarded to clangd-tidy";
            cmds = [
              "${clangdTidyExe} --clangd-executable ${lib.getExe' config.tools.clangd.package "clangd"} {{.CLI_ARGS}}"
            ];
          };
        };
      };
    };
  };
}
