# rising-tide flake context
{
  lib,
  flake-parts-lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.treefmt;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "treefmt.toml" cfg.config;
  treefmtExe = lib.getExe cfg.package;
in
{
  options.settings = mkSubmoduleOptions {
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

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      settings.tools.go-task = ifEnabled {
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
            "tool:treefmt" = {
              desc = "Run treefmt. Additional CLI arguments after `--` are forwarded to treefmt";
              cmds = [ (callTreefmt "{{.CLI_ARGS}}") ];
            };
          };
      };
    };
}
