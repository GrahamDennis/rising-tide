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
      propagatedBuildInputs = lib.mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
      hooks = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.hooks != { }) {
    mkShell.nativeBuildInputs = [
      (toolsPkgs.makeSetupHook {
        name = "shell-hooks.sh";
        propagatedBuildInputs = cfg.propagatedBuildInputs;
        substitutions = {
          inherit bashSafeName;
          relativePathToRoot = config.relativePaths.toRoot;
          bashCompletionPackage = toolsPkgs.bash-completion;
          shellHooks = lib.mapAttrsToList (name: script: ''
            ## Begin ${name}
            ${script}
            ## End ${name}

          '') cfg.hooks;
        };
      } ./mk-shell-hook.sh)
    ];
  };
}
