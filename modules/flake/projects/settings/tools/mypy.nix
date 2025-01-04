# rising-tide flake context
{ lib, ... }:
# project settings context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.mypy;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "mypy.toml" { tool.mypy = cfg.config; };
  mypyExe = lib.getExe cfg.package;
in
{
  options.tools.mypy = {
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
  };

  config = lib.mkIf cfg.enable {
    tools = {
      go-task = {
        enable = true;
        taskfile.tasks =
          let
            callMypy = args: "${mypyExe} --config-file=${toString configFile} ${args}";
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
