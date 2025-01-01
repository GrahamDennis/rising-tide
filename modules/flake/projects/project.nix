# rising-tide flake context
{ injector, lib, risingTideLib, ... }: let
  inherit (lib) types;
in
# user flake context
{ config, ... }: {
  imports = [ (injector.injectModule ./subprojects.nix) ];
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