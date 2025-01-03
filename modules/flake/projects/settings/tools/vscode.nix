# rising-tide flake context
{lib, ...}:
# project settings context
{
  config,
  toolsPkgs,
  ...
}: let
  cfg = config.tools.vscode;
  jsonFormat = toolsPkgs.formats.json {};
in {
  options.vscode = {
    enable = lib.mkEnableOption "Enable VSCode settings";
    settings = lib.mkOption {
      type = jsonFormat.type;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    nixagoRequests = lib.mkIf (cfg.settings != {}) [
      {
        data = cfg.settings;
        output = ".vscode/settings.json";
        format = "json";
      }
    ];
  };
}
