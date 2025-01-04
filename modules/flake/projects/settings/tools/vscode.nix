# rising-tide flake context
{ lib, ... }:
# project settings context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.vscode;
  settingsFormat = toolsPkgs.formats.json { };
in
{
  options.tools.vscode = {
    enable = lib.mkEnableOption "Enable VSCode settings";
    settings = lib.mkOption {
      description = ''
        Contents of the VSCode `.vscode/settings.json` file to generate.
      '';
      type = settingsFormat.type;
      default = { };
    };
    extensions = lib.mkOption {
      description = ''
        Contents of the VSCode `.vscode/extensions.json` file to generate. This file describes extensions
        that are recommended to be used with this project.
      '';
      type = settingsFormat.type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    tools.nixago.requests = lib.mkMerge [
      (lib.mkIf (cfg.settings != { }) [
        {
          data = cfg.settings;
          output = ".vscode/settings.json";
          format = "json";
        }
      ])
      (lib.mkIf (cfg.extensions != { }) [
        {
          data = cfg.extensions;
          output = ".vscode/extensions.json";
          format = "json";
        }
      ])
    ];
  };
}
