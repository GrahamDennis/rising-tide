# rising-tide flake context
{ lib, risingTideLib, ... }: let
  inherit (lib) types;
in
# user flake context
{ config, ... }: {
  options = {
    name = lib.mkOption {
      type = types.str;
      description = "The name of the project";
      example = "my-project";
    };
    relativePaths = {
      toRoot = lib.mkOption {
        type = risingTideLib.types.subpath;
        default = lib.path.subpath.join [config.relativePaths.parentProjectToRoot config.relativePaths.toParentProject];
      };
      toParentProject = lib.mkOption {
        type = types.nullOr risingTideLib.types.subpath;
        default = null;
      };
      parentProjectToRoot = lib.mkOption {
        type = types.nullOr risingTideLib.types.subpath;
        default = null;
      };
    };
  };
}