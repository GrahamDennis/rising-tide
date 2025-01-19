# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  enabledIn = projectConfig: projectConfig.tools.alejandra.enable;
  cfg = config.tools.alejandra;
  alejandraExe = lib.getExe cfg.package;
in
{
  options = {
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
        tools = {
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
        tools.vscode.settings = lib.mkIf (builtins.any enabledIn config.allProjectsList) {
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
