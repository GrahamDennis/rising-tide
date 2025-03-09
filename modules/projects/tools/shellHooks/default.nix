# rising-tide flake context
{
  risingTideLib,
  lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
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
      lib.mkMerge [
        (builtins.replaceStrings
          [ "@relativePathToRoot@" "@bashCompletionPackage@" "@bashSafeName@" "@shellHooks@" ]
          [
            config.relativePaths.toRoot
            (builtins.toString toolsPkgs.bash-completion)
            bashSafeName
            combinedShellHooks
          ]
          (builtins.readFile ./mk-shell-hook.sh)
        )

        (lib.mkOrder (lib.modules.defaultOrderPriority * 100) "configShellHook")
      ];
  };
}
