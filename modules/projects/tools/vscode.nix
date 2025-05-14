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
  getCfg = projectConfig: projectConfig.tools.vscode;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
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
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              options.enable = lib.mkEnableOption "Enable extension '${name}'";
            }
          )
        );
        default = { };
        example = {
          "jnoortheen.nix-ide".enable = true;
        };
      };
      extensions = lib.mkOption {
        description = ''
          Contents of the VSCode `.vscode/extensions.json` file to generate. This file describes extensions
          that are recommended to be used with this project. Instead modify `recommendedExtensions`.
        '';
        type = settingsFormat.type;
        readOnly = true;
        default = {
          recommendations = builtins.attrNames (
            lib.filterAttrs (_name: extensionCfg: extensionCfg.enable) cfg.recommendedExtensions
          );
        };
      };
      workspace = lib.mkOption {
        description = ''
          Contents of the VSCode `${config.name}.code-workspace` file to generate.
        '';
        type = settingsFormat.type;
        default = { };
      };
      launch = lib.mkOption {
        description = ''
          Contents of the VSCode `launch.json` file to generate.
        '';
        type = settingsFormat.type;
        default = { };
      };
      settingsFile = lib.mkOption {
        description = "The VSCode settings file to use";
        type = types.pathInStore;
        default = settingsFormat.generate "settings.json" cfg.settings;
      };
      extensionsFile = lib.mkOption {
        description = "The VSCode extensions file to use";
        type = types.pathInStore;
        default = settingsFormat.generate "extensions.json" cfg.extensions;
      };
      workspaceFile = lib.mkOption {
        description = "The VSCode workspace file to generate";
        type = types.pathInStore;
        default = settingsFormat.generate "${config.name}.code-workspace" cfg.workspace;
      };
      launchFile = lib.mkOption {
        description = "The VSCode launch.json file to generate";
        type = types.pathInStore;
        default = settingsFormat.generate "launch.json" cfg.launch;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        nixago.requests = lib.mkMerge [
          [
            {
              data = cfg.settingsFile;
              output = ".vscode/settings.json";
            }
          ]
          (lib.mkIf ((cfg.extensions.recommendations or [ ]) != [ ]) [
            {
              data = cfg.extensionsFile;
              output = ".vscode/extensions.json";
            }
          ])
          (lib.mkIf (cfg.workspace != { }) [
            {
              data = cfg.workspaceFile;
              output = ".vscode/${config.name}.code-workspace";
              hook.mode = "copy";
            }
          ])
          (lib.mkIf (cfg.launch != { }) [
            {
              data = cfg.launchFile;
              output = ".vscode/launch.json";
              hook.mode = "copy";
            }
          ])
        ];
      };
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.enabledSubprojectsList)) {
      tools.gitignore = {
        enable = true;
        rules = ''
          /.vscode/*.code-workspace
          .vscode/launch.json
        '';
      };
      tools.vscode.workspace = {
        settings = cfg.settings;
        extensions = cfg.extensions;
        folders = lib.mkMerge [
          (builtins.map (subproject: {
            path = "../${subproject.relativePaths.fromRoot}";
            name = subproject.name;
          }) (builtins.filter enabledIn config.enabledSubprojectsList))
          (lib.mkIf cfg.enable [
            {
              path = "..";
              name = "<root>";
            }
          ])
        ];
      };
    })
  ];
}
