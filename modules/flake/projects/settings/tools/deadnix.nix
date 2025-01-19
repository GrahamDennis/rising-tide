# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;

  cfg = config.settings.tools.deadnix;
  deadnixExe = lib.getExe cfg.package;
in
{
  options.settings = {
    tools.deadnix = {
      enable = lib.mkEnableOption "Enable deadnix integration";
      package = lib.mkPackageOption toolsPkgs "deadnix" { pkgsText = "toolsPkgs"; };
      arguments = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
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
            formatter.deadnix = {
              command = deadnixExe;
              options = cfg.arguments ++ [ "--edit" ];
              includes = [
                "*.nix"
              ];
            };
          };
        };
        go-task = ifEnabled {
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
