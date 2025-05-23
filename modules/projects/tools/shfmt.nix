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
  cfg = config.tools.shfmt;
  shfmtExe = lib.getExe cfg.package;
in
{
  options = {
    tools.shfmt = {
      enable = lib.mkEnableOption "Enable shfmt integration";
      package = lib.mkPackageOption toolsPkgs "shfmt" { pkgsText = "toolsPkgs"; };
      printerFlags = lib.mkOption {
        description = ''
          A list of additional CLI arguments to pass to shfmt configuration style options.

          Refer to the [shfmt documentation](https://github.com/mvdan/sh/blob/master/cmd/shfmt/shfmt.1.scd#printer-flags).
        '';
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
        enable = true;
        config = {
          formatter.shfmt = {
            command = shfmtExe;
            options = cfg.printerFlags ++ [ "--write" ];
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
            cmds = [ "${shfmtExe} ${lib.concatStringsSep " " cfg.printerFlags} {{.CLI_ARGS}}" ];
          };
        };
      };
    };
  };
}
