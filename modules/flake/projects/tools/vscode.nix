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
  cfg = config.tools.vscode;
  settingsFormat = toolsPkgs.formats.json { };
in
{
  options = {
    tools.vscode = {
      enable = lib.mkEnableOption "Enable VSCode settings";
      settings = lib.mkOption {
        description = ''
          Contents of the VSCode `.vscode/settings.json` file to generate.
        '';
        type = settingsFormat.type;
        default = { };
      };
      recommendedExtensions = lib.mkOption {
        description = ''
          An attrset of booleans to indicate which extensions should be included in `.vscode/extensions.json`.
        '';
        type = types.attrsOf types.bool;
        default = { };
        example = {
          "jnoortheen.nix-ide" = true;
        };
      };
      extensions = lib.mkOption {
        description = ''
          Contents of the VSCode `.vscode/extensions.json` file to generate. This file describes extensions
          that are recommended to be used with this project. Prefer to instead modify `recommendedExtensions`.
        '';
        type = settingsFormat.type;
        readOnly = true;
        default = {
          recommendations = builtins.attrNames (
            lib.filterAttrs (_name: enabled: enabled) cfg.recommendedExtensions
          );
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      nixago.requests = lib.mkMerge [
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
  };
}
