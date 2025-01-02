# rising-tide flake context
{
  injector,
  lib,
  self,
  ...
}: let
  inherit (lib) types;
  projectModule = self.modules.flake.project;
in
  # user flake project context
  {config, ...}: let
    parentProjectConfig = config;
  in {
    options = {
      subprojects = lib.mkOption {
        type = types.attrsOf (types.submoduleWith {
          modules = [
            projectModule
            # child project context
            ({name, ...}: {
              inherit name;
              relativePaths.parentProjectToRoot = parentProjectConfig.relativePaths.toRoot;
              systems = lib.mkDefault parentProjectConfig.systems;
            })
          ];
        });
        default = {};
      };
    };
  }
