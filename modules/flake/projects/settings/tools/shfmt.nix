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
  cfg = config.tools.shfmt;
  shfmtExe = lib.getExe cfg.package;
in
{
  options.tools.shfmt = {
    enable = lib.mkEnableOption "Enable shfmt integration";
    package = lib.mkPackageOption toolsPkgs "shfmt" { pkgsText = "toolsPkgs"; };
    styleOptions = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.shfmt = {
            command = shfmtExe;
            options = cfg.styleOptions ++ [ "--write" ];
            includes = [
              "*.sh"
              "*.bash"
              "*.bats"
            ];
          };
        };
      };
      go-task = {
        enable = true;
        taskfile.tasks = {
          "tool:shfmt" = {
            desc = "Run shfmt. Additional CLI arguments after `--` are forwarded to shfmt";
            cmds = [ "${shfmtExe} ${lib.concatStringsSep " " cfg.styleOptions} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
