# rising-tide flake context
{
  risingTideLib,
  lib,
  ...
}:
# project settings context
{
  config,
  project,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.uv;
  bashSafeName = risingTideLib.sanitizeBashIdentifier "uvShellHook-${project.relativePaths.toRoot}";
in
{
  options.tools.uv = {
    enable = lib.mkEnableOption "Enable uv integration";
    package = lib.mkPackageOption toolsPkgs "uv" { };
  };

  config = lib.mkIf cfg.enable {
    tools.all = [
      (toolsPkgs.makeSetupHook {
        name = "uv-shell-hook.sh";
        propagatedBuildInputs = [ cfg.package ];
        substitutions = {
          name = bashSafeName;
          relativePathToRoot = project.relativePaths.toRoot;
        };
      } ./uv-shell-hook.sh)
    ];
  };
}
