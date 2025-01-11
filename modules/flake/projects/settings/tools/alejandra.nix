# rising-tide flake context
{ lib, flake-parts-lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.alejandra;
  alejandraExe = lib.getExe cfg.package;
in
{
  options.settings = mkSubmoduleOptions {
    tools.alejandra = {
      enable = lib.mkEnableOption "Enable alejandra integration";
      package = lib.mkPackageOption toolsPkgs "alejandra" { pkgsText = "toolsPkgs"; };
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      settings.tools = {
        treefmt = ifEnabled {
          enable = true;
          config = {
            formatter.alejandra = {
              command = alejandraExe;
              includes = [ "*.nix" ];
            };
          };
        };
        go-task = ifEnabled {
          enable = true;
          taskfile.tasks = {
            "tool:alejandra" = {
              desc = "Run alejandra. Additional CLI arguments after `--` are forwarded to alejandra";
              cmds = [ "${alejandraExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
      rootProjectSettings.vscode.settings = ifEnabled {
        "nix.formatterPath" = alejandraExe;
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {
              "command" = [ alejandraExe ];
            };
          };
        };
      };
    };
}
