# rising-tide flake context
{ lib, injector, ... }:
# project context
{
  config,
  ...
}:
let
  cfg = config.conventions.risingTide.protobuf;
  getLangCfg = projectConfig: projectConfig.languages.protobuf;
  protobufEnabledIn = projectConfig: (getLangCfg projectConfig).enable;
in
{
  imports = injector.injectModules [ ./common.nix ];
  options.conventions.risingTide.protobuf = {
    enable = lib.mkEnableOption "Enable rising-tide protobuf conventions";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # protobuf tool configurations
      {
        conventions.risingTide.common.enable = true;
        tools = {
          buf = {
            config.modules = [ { path = "proto"; } ];
          };
        };
      }
      # Enable protobuf tools in protobuf projects
      (lib.mkIf (protobufEnabledIn config) {
        mkShell.enable = true;
        conventions.risingTide.python.enable = lib.mkForce false;
        languages.protobuf.src = lib.path.append config.absolutePath "./proto";
        tools = {
          buf.lint.enable = true;
          buf.format.enable = true;
          buf.breaking.enable = true;
          vscode.enable = true;
        };
      })
    ]
  );
}
