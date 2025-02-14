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
  cfg = config.tools.treefmt;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "treefmt.toml" cfg.config;
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
    };
  };

  config = lib.mkIf cfg.enable {
    tasks.check.serialTasks = [ "check:treefmt" ];
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
            cmds = [ (callTreefmt "{{if .CI}} --ci {{end}}") ];
          };
          "tool:treefmt" = {
            desc = "Run treefmt. Additional CLI arguments after `--` are forwarded to treefmt";
            cmds = [ (callTreefmt "{{.CLI_ARGS}}") ];
          };
        };
    };
  };
}
