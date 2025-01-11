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
  cfg = config.settings.tools.vscode;
  settingsFormat = toolsPkgs.formats.json { };
in
{
  options.settings = mkSubmoduleOptions {
    tools.vscode = {
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
  };

  config.settings.tools.nixago.requests = lib.mkIf cfg.enable (
    lib.mkMerge [
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
    ]
  );
}
