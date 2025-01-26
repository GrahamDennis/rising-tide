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
  cfg = config.tools.statix;
  settingsFormat = toolsPkgs.formats.toml { };
  # statix doesn't support multiple file targets
  statixFixExe = toolsPkgs.writeShellScript "statix-fix" ''
    set -o errexit
    for file in "$@"; do
      ${statixExe} fix --config '${cfg.configFile}' "$file"
    done
  '';

  statixExe = lib.getExe cfg.package;
in
{
  options = {
    tools.statix = {
      enable = lib.mkEnableOption "Enable statix integration";
      package = lib.mkPackageOption toolsPkgs "statix" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The statix TOML configuration file (`statix.toml`) to generate.

          Refer to the [statix documentation](https://git.peppe.rs/languages/statix/about/).'';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "statix.toml" cfg.config;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.statix = {
            command = statixFixExe;
            includes = [
              "*.nix"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:statix" = {
            desc = "Run statix. Additional CLI arguments after `--` are forwarded to deadnix";
            cmds = [ "${statixExe} --config ${cfg.configFile} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
