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
  cfg = config.tools.protolint;
  settingsFormat = toolsPkgs.formats.yaml { };
  bufExe = lib.getExe cfg.package;
in
{
  options = {
    tools.buf = {
      enable = lib.mkEnableOption "Enable buf tool";
      package = lib.mkPackageOption toolsPkgs "buf" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The buf YAML configuration file (`buf.yaml`) to generate.

          Refer to the [buf documentation](https://buf.build/docs/configuration/v2/buf-yaml/).'';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "buf.yaml" cfg.config;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        treefmt = {
          enable = true;
          config = {
            formatter.buf-lint = {
              command = bufExe;
              options = [
                "lint"
                "--config"
                cfg.configFile
              ];
              includes = [
                "*.proto"
              ];
            };
            formatter.buf-format = {
              command = bufExe;
              options = [
                "format"
                "--config"
                cfg.configFile
                "--write"
              ];
              includes = [
                "*.proto"
              ];
            };
          };
        };
        go-task = {
          enable = true;
          taskfile.tasks = {
            "tool:buf" = {
              desc = "Run buf. Additional CLI arguments after `--` are forwarded to buf";
              cmds = [ "${bufExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    })
  ];
}
