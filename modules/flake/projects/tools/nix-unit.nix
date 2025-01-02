# rising-tide flake context
{lib, ...}:
# project tools context
{
  config,
  pkgs,
  ...
}: let
  cfg = config.nix-unit;
  nix-unitExe = lib.getExe cfg.package;
in {
  options.nix-unit = {
    enable = lib.mkEnableOption "Enable nix-unit integration";
    package = lib.mkPackageOption pkgs "nix-unit" {};
    testsFlakeAttrPath = lib.mkOption {
      type = lib.types.str;
      default = "tests";
    };
  };

  config = lib.mkIf cfg.enable {
    go-task = {
      enable = true;
      taskfile.tasks = {
        check.deps = ["check:nix-unit"];
        "check:nix-unit" = {
          desc = "Run nix-unit tests";
          cmds = ["${nix-unitExe} --flake .#${cfg.testsFlakeAttrPath}"];
        };
        "tools:nix-unit" = {
          desc = "Run nix-unit. Additional CLI arguments after `--` are forwarded";
          cmds = ["${nix-unitExe} {{.CLI_ARGS}}"];
        };
      };
    };
  };
}
