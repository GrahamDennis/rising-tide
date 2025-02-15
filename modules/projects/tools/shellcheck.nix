# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.shellcheck;
  settingsFormat = toolsPkgs.formats.keyValue { listToValue = builtins.concatStringsSep ","; };
  configFile = settingsFormat.generate "shellcheckrc" cfg.config;
  shellCheckExe = lib.getExe cfg.package;
in
{
  options = {
    tools.shellcheck = {
      enable = lib.mkEnableOption "Enable shellcheck integration";
      # Use a smaller shellcheck package that doesn't depend on pandoc
      package = (lib.mkPackageOption toolsPkgs "shellcheck" { pkgsText = "toolsPkgs"; }) // {
        default = toolsPkgs.haskell.lib.compose.justStaticExecutables toolsPkgs.shellcheck.unwrapped;
      };
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

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
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
      go-task = {
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
