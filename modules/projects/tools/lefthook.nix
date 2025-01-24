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
  cfg = config.tools.lefthook;
  settingsFormat = toolsPkgs.formats.yaml { };
  lefthookExe = lib.getExe cfg.package;
in
{
  options = {
    tools.lefthook = {
      enable = lib.mkEnableOption "Enable left-hook integration";
      package = lib.mkPackageOption toolsPkgs "lefthook" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The left-hook YAML file to generate.
          Refer to the [left-hook documentation](https://evilmartians.github.io/lefthook/configuration/index.html).
        '';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "lefthook.yml" cfg.config;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      lefthook.config.rc = (
        lib.mkOptionDefault (
          toolsPkgs.writeShellScript "export-lefthook-path" ''
            export LEFTHOOK_BIN=${lefthookExe}
          ''
        )
      );
      nixago.requests = ([
        {
          data = cfg.configFile;
          hook.extra = ''
            ${lefthookExe} install
          '';
          output = ".lefthook.yml";
        }
      ]);

    };
  };
}
