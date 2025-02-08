# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
let
  inherit (lib) types;
in
# project context
{
  config,
  system,
  ...
}:
let
  cfg = config.tools.experimental.jetbrains;
  settingsFormat = risingTideLib.perSystem.${system}.formats.xml { };
in
{
  options = {
    tools.experimental.jetbrains = {
      enable = lib.mkEnableOption "Enable JetBrains IDE integration";
      xml = lib.mkOption {
        type = types.attrsOf settingsFormat.type;
        default = { };
        visible = "shallow";
      };
      xmlFiles = lib.mkOption {
        readOnly = true;
        type = types.attrsOf types.pathInStore;
        default = builtins.mapAttrs (name: xml: settingsFormat.generate name xml) cfg.xml;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    tools.nixago.requests = lib.mapAttrsToList (name: file: {
      data = file;
      output = ".idea/${name}";
      hook.mode = "copy";
    }) cfg.xmlFiles;
  };
}
