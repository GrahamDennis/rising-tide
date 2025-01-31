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
  cfg = config.tools.taplo;
  taploExe = lib.getExe cfg.package;
  settingsFormat = toolsPkgs.formats.toml { };
in
{
  options = {
    tools.taplo = {
      enable = lib.mkEnableOption "Enable taplo integration (TOML formatter)";
      package = lib.mkPackageOption toolsPkgs "taplo" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The taplo TOML file to generate.
          Refer to the [taplo configuration documentation](https://taplo.tamasfe.dev/configuration/file.html)
        '';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "taplo.toml" cfg.config;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.taplo = {
            command = taploExe;
            options = [
              "format"
              "--config"
              cfg.configFile
            ];
            includes = [
              "*.toml"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:taplo" = {
            desc = "Run taplo. Additional CLI arguments after `--` are forwarded to taplo";
            cmds = [ "${taploExe} {{.CLI_ARGS}}" ];
            env.TAPLO_CONFIG = cfg.configFile;
          };
        };
      };
    };
  };
}
