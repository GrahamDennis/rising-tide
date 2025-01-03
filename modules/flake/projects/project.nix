# rising-tide flake context
{
  injector,
  lib,
  risingTideLib,
  flake-parts-lib,
  self,
  ...
}:
let
  inherit (lib) types;
  projectModule =
    # project context
    { config, ... }:
    {
      _file = ./project.nix;
      options = {
        name = lib.mkOption {
          type = types.str;
          description = "The name of the project";
          example = "my-project";
        };
        relativePaths = {
          toRoot = lib.mkOption {
            type = risingTideLib.types.subpath;
            default = lib.path.subpath.join [
              config.relativePaths.parentProjectToRoot
              config.relativePaths.toParentProject
            ];
          };
          toParentProject = lib.mkOption {
            type = risingTideLib.types.subpath;
          };
          parentProjectToRoot = lib.mkOption {
            type = risingTideLib.types.subpath;
            readOnly = true;
          };
        };
        systems = lib.mkOption {
          type = types.listOf types.str;
        };
        defaultSettings = lib.mkOption {
          type = types.deferredModule;
          default = { };
        };
        settings = lib.mkOption {
          type =
            let
              projectConfig = config;
              emptyChildProjectSettings = {
                parentProjectSettings = { };
                rootProjectSettings = { };
              };
            in
            flake-parts-lib.mkPerSystemType (
              {
                system,
                ...
              }:
              {
                imports =
                  [ (injector.injectModule ./settings) ]
                  # Apply default settings
                  ++ [ projectConfig.defaultSettings ]
                  # Apply parent project settings from child projects (child projects may not support the same systems as the parent)
                  ++ (lib.mapAttrsToList (
                    _subprojectName: subprojectConfig:
                    (subprojectConfig.settings.${system} or emptyChildProjectSettings).parentProjectSettings
                  ) projectConfig.subprojects)
                  # Apply root project settings from child projects if this is the root project
                  ++ (lib.optionals (projectConfig.relativePaths.toRoot == "./.") (
                    lib.mapAttrsToList (
                      _subprojectName: subprojectConfig:
                      (subprojectConfig.settings.${system} or emptyChildProjectSettings).rootProjectSettings
                    ) projectConfig.subprojects
                  ));
                options = {
                  parentProjectSettings = lib.mkOption {
                    type = types.deferredModule;
                    default = { };
                  };
                  rootProjectSettings = lib.mkOption {
                    type = types.deferredModuleWith {
                      staticModules = lib.mapAttrsToList (
                        _subprojectName: subprojectConfig:
                        (subprojectConfig.settings.${system} or emptyChildProjectSettings).rootProjectSettings
                      ) projectConfig.subprojects;
                    };
                    default = { };
                  };
                };
              }
            );
          default = { };
          apply =
            modules:
            let
              generatePerSystemSettings =
                system:
                (lib.evalModules {
                  inherit modules;
                  prefix = [
                    "settings"
                    system
                  ];
                  specialArgs = {
                    inherit system;
                    project = {
                      inherit (config) relativePaths name;
                    };
                  };
                }).config;
            in
            lib.genAttrs config.systems generatePerSystemSettings;
        };
        subprojects = lib.mkOption {
          type = types.attrsOf (
            types.submoduleWith {
              modules =
                let
                  parentProjectConfig = config;
                in
                [
                  projectModule
                  # child project context
                  (
                    { name, ... }:
                    {
                      inherit name;
                      relativePaths.parentProjectToRoot = parentProjectConfig.relativePaths.toRoot;
                      systems = lib.mkDefault parentProjectConfig.systems;
                      # Inherit defaults from the parent project
                      defaultSettings = parentProjectConfig.defaultSettings;
                    }
                  )
                ];
            }
          );
          default = { };
        };
        tools = lib.mkOption {
          type = types.attrsOf (types.listOf types.package);
          readOnly = true;
          default = lib.mapAttrs (_system: perSystemSettings: perSystemSettings.tools.all) config.settings;
        };
      };
    };
in
projectModule
