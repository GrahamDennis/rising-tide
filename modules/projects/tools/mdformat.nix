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
  cfg = config.tools.mdformat;
  settingsFormat = toolsPkgs.formats.toml { };
  configFile = settingsFormat.generate "mdformat.toml" cfg.config;
  mdformatExe = lib.getExe cfg.package;
in
{
  options = {
    tools.mdformat = {
      enable = lib.mkEnableOption "Enable mdformat integration";
      package = lib.mkPackageOption toolsPkgs "mdformat" { pkgsText = "toolsPkgs"; } // {
        default = toolsPkgs.mdformat.withPlugins (
          ps: with ps; [
            mdformat-gfm
            mdformat-frontmatter
            mdformat-footnote
            # mdformat-gfm-alerts
          ]
        );
      };
      config = lib.mkOption {
        description = ''
          The mdformat TOML file to generate.
          Refer to the [mdformat documentation](https://mdformat.readthedocs.io/en/stable/users/configuration_file.html).
        '';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = configFile;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      nixago.requests = lib.mkIf (cfg.config != { }) [
        {
          data = cfg.configFile;
          output = ".mdformat.toml";
        }
      ];
      treefmt = {
        enable = true;
        config = {
          formatter.mdformat = {
            command = mdformatExe;
            includes = [
              "*.md"
              "*.markdown"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:mdformat" = {
            desc = "Run mdformat. Additional CLI arguments after `--` are forwarded to mdformat";
            cmds = [ "${mdformatExe} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
