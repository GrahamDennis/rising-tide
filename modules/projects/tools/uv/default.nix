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
  cfg = config.tools.uv;
  bashSafeName = risingTideLib.sanitizeBashIdentifier "uvShellHook-${config.relativePaths.toRoot}";
in
{
  options = {
    tools.uv = {
      enable = lib.mkEnableOption "Enable uv integration";
      package = lib.mkPackageOption toolsPkgs "uv" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkIf cfg.enable {
    allTools = [
      (toolsPkgs.makeSetupHook {
        name = "uv-shell-hook.sh";
        propagatedBuildInputs = [ cfg.package ];
        substitutions = {
          name = bashSafeName;
          relativePathToRoot = config.relativePaths.toRoot;
        };
      } ./uv-shell-hook.sh)
    ];
  };
}
