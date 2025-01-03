# rising-tide flake context
{
  lib,
  inputs,
  ...
}:
# project tools context
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
  options.tools.treefmt = {
    enable = lib.mkEnableOption "Enable treefmt integration";
    package = lib.mkPackageOption toolsPkgs "treefmt" { };
    config = lib.mkOption {
      type = settingsFormat.type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    tools.go-task = {
      enable = true;
      taskfile.tasks =
        let
          callTreefmt =
            args: "${treefmtExe} --config-file ${configFile} ${args} --tree-root . --on-unmatched debug";
        in
        {
          check.deps = [ "check:treefmt" ];
          "check:treefmt" = {
            desc = "Reformat with treefmt";
            cmds = [ (callTreefmt "{{if .CI}} --ci {{end}}") ];
          };
          "tools:treefmt" = {
            desc = "Run treefmt. Additional CLI arguments after `--` are forwarded to treefmt";
            cmds = [ (callTreefmt "{{.CLI_ARGS}}") ];
          };
        };
    };
  };
}
