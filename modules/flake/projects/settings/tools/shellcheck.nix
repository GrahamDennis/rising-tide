# rising-tide flake context
{ lib, flake-parts-lib, ... }:
# project settings context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.shellcheck;
  settingsFormat = toolsPkgs.formats.keyValue { };
  configFile = settingsFormat.generate "shellcheckrc" cfg.config;
  shellCheckExe = lib.getExe cfg.package;
in
{
  options.settings = mkSubmoduleOptions {
    tools.shellcheck = {
      enable = lib.mkEnableOption "Enable shellcheck integration";
      package = lib.mkPackageOption toolsPkgs "shellcheck" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The shellcheck configuration file (`shellcheckrc`) to generate.

          Refer to the [shellcheck documentation](https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md#rc-files).
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
        treefmt = ifEnabled {
          enable = true;
          config = {
            formatter.shellcheck = {
              command = shellCheckExe;
              options = [
                "--rcfile"
                (toString configFile)
              ];
              includes = [
                "*.sh"
                "*.bash"
                "*.bats"
              ];
            };
          };
        };
        go-task = ifEnabled {
          enable = true;
          taskfile.tasks = {
            "tool:shellcheck" = {
              desc = "Run shellcheck. Additional CLI arguments after `--` are forwarded to shellcheck";
              cmds = [ "${shellCheckExe} --rcfile ${toString configFile} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    };
}
