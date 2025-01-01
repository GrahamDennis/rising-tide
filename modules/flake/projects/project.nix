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
        # readOnly = true;
        # default = lib.path.subpath.join [parentProjectRelativePathToRoot config.relativePathToParentProject];
      };
      # toParentProject = lib.mkOption {
      #   type = risingTideLib.types.subpath;
      # };
      # parentProjectToRoot = lib.mkOption {
      #   type = risingTideLib.types.subpath;
      # };
    };
  };
}