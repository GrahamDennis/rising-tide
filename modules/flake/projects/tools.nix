# rising-tide flake context
{
  injector,
  lib,
  self,
  ...
}: let
  inherit (lib) types;
  toolsModule = injector.injectModule ./tools;
in
  # user flake project context
  {config, ...}: let
    parentProjectConfig = config;
  in {
    options = {
      tools = lib.mkOption {
        type = types.lazyAttrsOf types.unspecified;
        readOnly = true;
      };
    };
    config = {
      perSystem = {system, ...}: {
        options = {
          tools = lib.mkOption {
            type = types.submoduleWith {
              specialArgs = {
                inherit system;
                inherit (parentProjectConfig) relativePaths;
              };

              modules =
                [toolsModule]
                ++ (lib.mapAttrsToList (_subprojectName: subprojectConfig: subprojectConfig.allSystems.${system}.parentProjectTools) parentProjectConfig.subprojects)
                ++ (lib.optional (parentProjectConfig.relativePaths.toRoot == "./.") parentProjectConfig.allSystems.${system}.rootProjectTools);
            };
            default = {};
          };
          parentProjectTools = lib.mkOption {
            type = types.deferredModule;
            default = {};
          };
          rootProjectTools = lib.mkOption {
            type = types.deferredModuleWith {
              staticModules = lib.mapAttrsToList (_subprojectName: subprojectConfig: subprojectConfig.allSystems.${system}.rootProjectTools) parentProjectConfig.subprojects;
            };
            default = {};
          };
        };
      };

      tools = lib.mapAttrs (system: v: v.tools) config.allSystems;
    };
  }
