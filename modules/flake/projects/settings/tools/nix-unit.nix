# rising-tide flake context
{ lib, ... }:
# project tools context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.nix-unit;
  nix-unitExe = lib.getExe cfg.package;
in
{
  options.tools.nix-unit = {
    enable = lib.mkEnableOption "Enable nix-unit integration";
    package = lib.mkPackageOption toolsPkgs "nix-unit" { };
    testsFlakeAttrPath = lib.mkOption {
      type = lib.types.str;
      default = "tests";
    };
  };

  config = lib.mkIf cfg.enable {
    tools.go-task = {
      enable = true;
      taskfile.tasks = {
        test.deps = [ "test:nix-unit" ];
        "test:nix-unit" = {
          desc = "Run nix-unit tests";
          cmds = [ "${nix-unitExe} --show-trace --flake .#${cfg.testsFlakeAttrPath}" ];
        };
        "tools:nix-unit" = {
          desc = "Run nix-unit. Additional CLI arguments after `--` are forwarded";
          cmds = [ "${nix-unitExe} {{.CLI_ARGS}}" ];
        };
      };
    };
  };
}
