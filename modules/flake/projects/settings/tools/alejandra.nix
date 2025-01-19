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
  enabledIn = projectConfig: projectConfig.settings.tools.alejandra.enable;
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
      ifEnabled = lib.mkIf (enabledIn config);
    in
    lib.mkMerge [
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
      }
      (lib.mkIf config.isRootProject {
        settings.tools.vscode.settings = lib.mkIf (builtins.any enabledIn config.allProjectsList) {
          "nix.formatterPath" = alejandraExe;
          "nix.serverSettings" = {
            "nil" = {
              "formatting" = {
                "command" = [ alejandraExe ];
              };
            };
          };
        };
      })
    ];
}
