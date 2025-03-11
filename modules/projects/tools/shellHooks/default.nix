# rising-tide flake context
{
  risingTideLib,
  lib,
  ...
}:
# project context
{
  config,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.shellHooks;
  bashSafeName = risingTideLib.sanitizeBashIdentifier "shellHooks-${config.relativePaths.toRoot}";
in
{
  options = {
    tools.shellHooks = {
      enable = lib.mkEnableOption "Enable shell hooks";
      hooks = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.hooks != { }) {
    mkShell.shellHook =
      let
        combinedShellHooks = lib.concatMapAttrsStringSep "\n" (name: script: ''
          ## Begin ${name}
          ${script}
          ## End ${name}

        '') cfg.hooks;
      in
      (builtins.replaceStrings
        [ "@relativePathToRoot@" "@bashSafeName@" "@shellHooks@" ]
        [ config.relativePaths.toRoot bashSafeName combinedShellHooks ]
        (builtins.readFile ./mk-shell-hook.sh)
      );
  };
}
