# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  inherit (lib) types;
  cfg = config.conventions.risingTide.common;
in
{
  options = {
    conventions.risingTide.common = {
      enable = lib.mkEnableOption "Enable rising-tide common conventions";
      preCommitEnabledFormatters = lib.mkOption {
        description = ''
          The treefmt formatters that are run during pre-commit checks.
        '';
        type = types.attrsOf types.bool;
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tasks.pre-commit = {
      enable = true;
      dependsOn = [
        "check:treefmt:${
          builtins.concatStringsSep "," (
            lib.pipe cfg.preCommitEnabledFormatters [
              (lib.filterAttrs (_formatter: enabled: enabled))
              builtins.attrNames
            ]
          )
        }"
      ];
    };
    tools.go-task = {
      taskfile.run = "when_changed";
    };
    tools.shellcheck = {
      config.disable = [ "SC1091" ];
    };
    conventions.risingTide.common.preCommitEnabledFormatters = builtins.mapAttrs (
      _formatter: enabled: lib.mkDefault enabled
    ) config.tools.treefmt.defaultEnabledFormatters;
  };
}
