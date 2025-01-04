# rising-tide flake context
{ lib, ... }:
# project settings context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.deadnix;
  deadnixExe = lib.getExe cfg.package;
in
{
  options.tools.deadnix = {
    enable = lib.mkEnableOption "Enable deadnix integration";
    package = lib.mkPackageOption toolsPkgs "deadnix" { pkgsText = "toolsPkgs"; };
    arguments = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.deadnix = {
            command = deadnixExe;
            options = cfg.arguments ++ [ "--fail" ];
            includes = [
              "*.nix"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:deadnix" = {
            desc = "Run deadnix. Additional CLI arguments after `--` are forwarded to deadnix";
            cmds = [ "${deadnixExe} ${lib.concatStringsSep " " cfg.arguments} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
