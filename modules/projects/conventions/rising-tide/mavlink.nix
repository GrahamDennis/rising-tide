# rising-tide flake context
{ lib, injector, ... }:
# project context
{
  config,
  ...
}:
let
  cfg = config.conventions.risingTide.mavlink;
  getLangCfg = projectConfig: projectConfig.languages.mavlink;
  mavlinkEnabledIn = projectConfig: (getLangCfg projectConfig).enable;
in
{
  imports = injector.injectModules [ ./common.nix ];
  options.conventions.risingTide.mavlink = {
    enable = lib.mkEnableOption "Enable rising-tide mavlink conventions";
  };

  config = lib.mkIf (cfg.enable && (mavlinkEnabledIn config)) {
    mkShell.enable = true;
    tools = {
      cue-schema = {
        enable = true;
        schemaFlakeAttrPath = (getLangCfg config).subprojectNames.cueSchema;
      };
    };
  };
}
