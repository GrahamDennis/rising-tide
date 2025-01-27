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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        nil.enable = true;
        treefmt = {
          enable = true;
          config = {
            formatter.alejandra = {
              command = alejandraExe;
              includes = [ "*.nix" ];
            };
          };
        };
        go-task = {
          enable = true;
          taskfile.tasks = {
            "tool:alejandra" = {
              desc = "Run alejandra. Additional CLI arguments after `--` are forwarded to alejandra";
              cmds = [ "${alejandraExe} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.vscode.settings = {
        "nix.formatterPath" = [ alejandraExe ];
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
