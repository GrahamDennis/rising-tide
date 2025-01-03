# rising-tide flake context
{ lib, ... }:
# project tools context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.alejandra;
  alejandraExe = lib.getExe cfg.package;
in
{
  options.tools.alejandra = {
    enable = lib.mkEnableOption "Enable alejandra integration";
    package = lib.mkPackageOption toolsPkgs "alejandra" { };
  };

  config = lib.mkIf cfg.enable {
    tools = {
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
          "tools:alejandra" = {
            desc = "Run alejandra. Additional CLI arguments after `--` are forwarded to alejandra";
            cmds = [ "${alejandraExe} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
