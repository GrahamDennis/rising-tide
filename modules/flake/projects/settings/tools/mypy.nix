# rising-tide flake context
{ lib, flake-parts-lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  inherit (lib) types;
  cfg = config.settings.tools.mypy;
  settingsFormat = toolsPkgs.formats.toml { };
  mypyExe = lib.getExe cfg.package;
in
{
  options.settings = mkSubmoduleOptions {
    tools.mypy = {
      enable = lib.mkEnableOption "Enable mypy integration";
      package = lib.mkPackageOption toolsPkgs "mypy" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The mypy TOML file to generate. All configuration here is nested under the `tool.mypy` key
          in the generated file.

          Refer to the [mypy documentation](https://mypy.readthedocs.io/en/stable/config_file.html),
          in particular the [pyproject.toml format documentation](https://mypy.readthedocs.io/en/stable/config_file.html#using-a-pyproject-toml-file).
        '';
        type = settingsFormat.type;
        default = { };
      };
      perModuleOverrides = lib.mkOption {
        description = ''
          An attrset of overrides where the key of the attrset is the module that the override is for.
        '';
        type = types.attrsOf (settingsFormat.type);
        default = { };
        example = {
          "mycode.foo.*" = {
            disallow_untyped_defs = false;
          };
        };
      };
      mergedConfig = lib.mkOption {
        readOnly = true;
        description = ''
          The merged mypy configuration that will be written to a mypy.toml file.
        '';
        type = settingsFormat.type;
        default =
          let
            checkedBaseConfig =
              if cfg.config ? "overrides" then
                throw "Do not set `overrides` in mypy config. Instead set the overrides in `tools.mypy.perModuleOverrides.\"<modulePath>\"`."
              else
                cfg.config;
          in
          {
            tool.mypy = lib.mkMerge [
              # base configuration
              checkedBaseConfig
              # per module overrides
              (lib.mkIf (cfg.perModuleOverrides != { }) ({
                overrides = lib.mapAttrsToList (
                  module: override: override // { inherit module; }
                ) cfg.perModuleOverrides;
              }))
            ];
          };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "mypy.toml" cfg.mergedConfig;
      };
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      settings.tools = {
        go-task = ifEnabled {
          enable = true;
          taskfile.tasks =
            let
              callMypy = args: "${mypyExe} --config-file=${toString cfg.configFile} ${args}";
            in
            {
              # Mypy must run after treefmt, so we run it as a command not a dependency
              # (as dependencies run in parallel)
              check.cmds = [ { task = "check:mypy"; } ];
              "check:mypy" = {
                desc = "Run mypy type checker";
                cmds = [ (callMypy "src tests") ];
              };
              "tool:mypy" = {
                desc = "Run mypy. Additional CLI arguments after `--` are forwarded to mypy";
                cmds = [ (callMypy "{{.CLI_ARGS}}") ];
              };
            };
        };
      };
    };
}
