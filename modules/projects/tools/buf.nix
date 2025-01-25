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
  cfg = config.tools.buf;
  settingsFormat = toolsPkgs.formats.yaml { };
  bufExe = lib.getExe cfg.package;
in
{
  options = {
    tools.buf = {
      enable = lib.mkEnableOption "Enable buf tool" // {
        default = cfg.lint.enable || cfg.format.enable;
      };
      lint.enable = lib.mkEnableOption "Enable buf lint tool";
      format.enable = lib.mkEnableOption "Enable buf format tool";
      breaking = {
        enable = lib.mkEnableOption "Enable buf breaking tool";
        against = lib.mkOption {
          type = types.str;
          description = "What to compare against";
        };
      };
      package = lib.mkPackageOption toolsPkgs "buf" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The buf YAML configuration file (`buf.yaml`) to generate.

          Refer to the [buf documentation](https://buf.build/docs/configuration/v2/buf-yaml/).'';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "buf.yaml" cfg.config;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        buf.config = {
          version = lib.mkDefault "v2";
        };
        treefmt = {
          enable = true;
          config =
            let
              bufLintExe = lib.getExe (
                toolsPkgs.writeShellScriptBin "buf-lint" ''
                  for file in "$@"; do
                    ${bufExe} lint --config '${cfg.configFile}' "$file"
                  done
                ''
              );
              bufFormatExe = lib.getExe (
                toolsPkgs.writeShellScriptBin "buf-format" ''
                  for file in "$@"; do
                    ${bufExe} format --config '${cfg.configFile}' --write "$file"
                  done
                ''
              );
            in
            {
              formatter.buf-lint = lib.mkIf cfg.lint.enable {
                command = bufLintExe;
                includes = [ "*.proto" ];
              };
              formatter.buf-format = lib.mkIf cfg.format.enable {
                command = bufFormatExe;
                includes = [ "*.proto" ];
              };
            };
        };
        go-task = {
          enable = true;
          taskfile.tasks = lib.mkMerge [
            {
              "tool:buf" = {
                desc = "Run buf. Additional CLI arguments after `--` are forwarded to buf";
                cmds = [ "${bufExe} --config ${cfg.configFile} {{.CLI_ARGS}}" ];
              };
            }
            (lib.mkIf cfg.breaking.enable {
              check.deps = [ "check:buf-breaking" ];
              "check:buf-breaking" = lib.mkIf cfg.breaking.enable {
                desc = "Ensure that there are no breaking changes in the proto files";
                cmds = [ "${bufExe} breaking --config ${cfg.configFile} --against ${cfg.breaking.against}" ];
              };
            })
          ];
        };
      };
    })
  ];
}
