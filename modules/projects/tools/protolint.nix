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
  protolintExe = lib.getExe cfg.package;
in
{
  options = {
    tools.protolint = {
      enable = lib.mkEnableOption "Enable protolint integration";
      package = lib.mkPackageOption toolsPkgs "protolint" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The protolint YAML configuration file (`protolint.yaml`) to generate.

          Refer to the [protolint example configuration](https://github.com/yoheimuta/protolint/blob/master/_example/config/.protolint.yaml).'';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "protolint.yaml" cfg.config;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        treefmt = {
          enable = true;
          config = {
            formatter.protolint = {
              command = protolintExe;
              options = [
                "lint"
                "-fix"
                "-config_path=${cfg.configFile}"
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
            "tool:protolint" = {
              desc = "Run protolint. Additional CLI arguments after `--` are forwarded to protolint";
              cmds = [ "${protolintExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    })
  ];
}
