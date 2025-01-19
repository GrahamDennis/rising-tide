# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.settings.tools.lefthook;
  settingsFormat = toolsPkgs.formats.yaml { };
  lefthookExe = lib.getExe cfg.package;
in
{
  options.settings = {
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
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      settings.tools = {
        lefthook.config.rc = ifEnabled (
          lib.mkOptionDefault (
            toolsPkgs.writeShellScript "export-lefthook-path" ''
              export LEFTHOOK_BIN=${lefthookExe}
            ''
          )
        );
        nixago.requests = ifEnabled ([
          {
            data = cfg.config;
            hook.extra = ''
              ${lefthookExe} install
            '';
            output = ".lefthook.yml";
            format = "yaml";
          }
        ]);

      };
    };
}
