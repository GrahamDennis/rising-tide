# rising-tide flake context
{ lib, ... }:
# project settings context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.lefthook;
  settingsFormat = toolsPkgs.formats.yaml { };
  lefthookExe = lib.getExe cfg.package;
in
{
  options.tools.lefthook = {
    enable = lib.mkEnableOption "Enable left-hook integration";
    package = lib.mkPackageOption toolsPkgs "lefthook" { };
    config = lib.mkOption {
      type = settingsFormat.type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      lefthook.config.rc = lib.mkOptionDefault (
        toolsPkgs.writeShellScript "export-lefthook-path" ''
          export LEFTHOOK_BIN=${lefthookExe}
        ''
      );
      nixago.requests = [
        {
          data = cfg.config;
          hook.extra = ''
            ${lefthookExe} install
          '';
          output = ".lefthook.yml";
          format = "yaml";
        }
      ];

    };
  };
}
