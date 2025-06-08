# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.treefmt;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "treefmt.toml" cfg.configWithDefaults;
  treefmtExe = lib.getExe cfg.package;
in
{
  options = {
    tools.treefmt = {
      enable = lib.mkEnableOption "Enable treefmt integration";
      package = lib.mkPackageOption toolsPkgs "treefmt" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The treefmt TOML configuration file (`treefmt.toml`) to generate.

          Refer to the [treefmt documentation](https://treefmt.com/latest/getting-started/configure/).
        '';
        type = settingsFormat.type;
        default = { };
      };
      configWithDefaults = lib.mkOption {
        internal = true;
        readOnly = true;
        type = settingsFormat.type;
        default = cfg.config // {
          formatters = lib.pipe cfg.defaultEnabledFormatters [
            (lib.filterAttrs (_formatter: enabled: enabled))
            builtins.attrNames
          ];
        };
      };
      defaultEnabledFormatters = lib.mkOption {
        description = ''
          The treefmt formatters that are run by default.
        '';
        type = types.attrsOf types.bool;
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tasks.check.serialTasks = [ "check:treefmt" ];
    tools.treefmt.defaultEnabledFormatters = builtins.mapAttrs (
      _formatter: _formatterConfig: lib.mkDefault true
    ) cfg.config.formatter;
    tools.go-task = {
      enable = true;
      taskfile.tasks =
        let
          callTreefmt =
            args: "${treefmtExe} --config-file ${configFile} ${args} --tree-root . --on-unmatched debug";
        in
        {
          "check:treefmt" = {
            desc = "Reformat with treefmt";
            cmds = [ (callTreefmt "{{if .CI}} --no-cache {{end}}") ];
          };
          "check:treefmt:*" = {
            desc = "Reformat with a specific treefmt formatter (e.g. `check:treefmt:shellcheck`)";
            vars.FORMATTER = "{{index .MATCH 0}}";
            label = "check:treefmt:{{.FORMATTER}}";
            prefix = "check:treefmt:{{.FORMATTER}}";
            cmds = [ (callTreefmt "--formatters {{.FORMATTER}} {{if .CI}} --no-cache {{end}}") ];
          };
          "tool:treefmt" = {
            desc = "Run treefmt. Additional CLI arguments after `--` are forwarded to treefmt";
            cmds = [ (callTreefmt "{{.CLI_ARGS}}") ];
          };
        };
    };
  };
}
