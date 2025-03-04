# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{
  config,
  ...
}:
{
  options = {
    overlay = lib.mkOption {
      type = risingTideLib.types.overlay;
      default = _final: _prev: { };
    };
  };
  config = {
    # Merge all child project overlays
    overlay = lib.mkMerge (
      lib.mapAttrsToList (_name: subprojectConfig: subprojectConfig.overlay) config.subprojects
    );
  };
}
