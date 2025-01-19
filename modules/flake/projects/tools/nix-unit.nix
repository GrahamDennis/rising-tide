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
  options = {
    tools.nix-unit = {
      enable = lib.mkEnableOption "Enable nix-unit integration";
      package = lib.mkPackageOption toolsPkgs "nix-unit" { pkgsText = "toolsPkgs"; };
      testsFlakeAttrPath = lib.mkOption {
        description = "The flake attribute path that contains nix-unit tests";
        type = lib.types.str;
        default = "tests";
      };
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      tools.go-task = ifEnabled {
        enable = true;
        taskfile.tasks = {
          test.deps = [ "test:nix-unit" ];
          "test:nix-unit" = {
            desc = "Run nix-unit tests";
            cmds = [ "${nix-unitExe} --show-trace --flake .#${cfg.testsFlakeAttrPath}" ];
          };
          "tool:nix-unit" = {
            desc = "Run nix-unit. Additional CLI arguments after `--` are forwarded";
            cmds = [ "${nix-unitExe} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
}
