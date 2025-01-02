# rising-tide flake context
{lib, ...}:
# project tools context
{
  config,
  pkgs,
  ...
}: let
  cfg = config.alejandra;
  alejandraExe = lib.getExe cfg.package;
in {
  options.alejandra = {
    enable = lib.mkEnableOption "Enable alejandra integration";
    package = lib.mkPackageOption pkgs "alejandra" {};
  };

  config = lib.mkIf cfg.enable {
    treefmt = {
      enable = true;
      config = {
        formatter.alejandra = {
          command = alejandraExe;
          includes = ["*.nix"];
        };
      };
    };
    go-task = {
      enable = true;
      taskfile.tasks = {
        "tools:alejandra" = {
          desc = "Run alejandra. Additional CLI arguments after `--` are forwarded to alejandra";
          cmds = ["${alejandraExe} {{.CLI_ARGS}}"];
        };
      };
    };
  };
}
