# rising-tide flake context
{
  lib,
  ...
}:
# project context
{ config, toolsPkgs, ... }:
let
  cfg = config.tasks.ci.check-derivation-unchanged;
  jqExe = lib.getExe toolsPkgs.jq;
  nixDiffExe = lib.getExe toolsPkgs.nix-diff;
in
{
  options = {
    tasks.ci.check-derivation-unchanged = {
      enable = lib.mkEnableOption "Enable check-derivation-unchanged task";
      derivationAttrPath = lib.mkOption {
        type = lib.types.str;
        default = "_all-project-packages";
        description = "The attribute path to the derivation to check for changes";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tasks.ci.serialTasks = [ "ci:check-derivation-unchanged" ];
    tools.go-task = {
      taskfile.tasks = {
        "ci:check-derivation-unchanged" = {
          desc = "Check if the derivation has changed";
          vars.TEMPORARY_FILE.sh = "mktemp -p ./";
          cmds = [
            { defer = "git rm --ignore-unmatch --force {{.TEMPORARY_FILE}}"; }
            "nix build --out-link build/check-derivation-unchanged/original.drv $(nix derivation show .#${cfg.derivationAttrPath} | ${jqExe} --raw-output 'keys[]')"
            "git add --intent-to-add {{.TEMPORARY_FILE}}"
            "nix build --out-link build/check-derivation-unchanged/modified.drv $(nix derivation show .#${cfg.derivationAttrPath} | ${jqExe} --raw-output 'keys[]')"
            ''
              if [ "$(readlink build/check-derivation-unchanged/original.drv)" != "$(readlink build/check-derivation-unchanged/modified.drv)" ]; then
                echo 'Derivation .#${cfg.derivationAttrPath} has changed';
                ${nixDiffExe} build/check-derivation-unchanged/original.drv build/check-derivation-unchanged/modified.drv
              fi
            ''
          ];
        };
      };
    };
  };
}
