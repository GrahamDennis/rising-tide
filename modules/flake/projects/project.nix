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
          description = "The name of the project";
          type = types.str;
          example = "my-project";
        };
        relativePaths = {
          toRoot = lib.mkOption {
            description = "The path from the project to the root of the flake";
            type = risingTideLib.types.subpath;
            default = lib.path.subpath.join [
              config.relativePaths.parentProjectToRoot
              config.relativePaths.toParentProject
            ];
            defaultText = lib.literalExpression ''
              lib.path.subpath.join [
                config.relativePaths.parentProjectToRoot
                config.relativePaths.toParentProject
              ]
            '';
          };
          toParentProject = lib.mkOption {
            description = "The path from the project to the parent project";
            type = risingTideLib.types.subpath;
          };
          parentProjectToRoot = lib.mkOption {
            description = "The path from the parent project to the root of the flake";
            type = risingTideLib.types.subpath;
            readOnly = true;
          };
        };
        systems = lib.mkOption {
          description = ''
            All the system types supported by this project.

            In other words, all valid values for `system` in e.g. `settings.<system>` and `tools.<system>`.
          '';
          type = types.listOf types.str;
        };
        defaultSettings = lib.mkOption {
          description = "`settings` configs that apply to this project and all nested subprojects";
          type = types.deferredModule;
          default = { };
        };
        settings = lib.mkOption {
          description = "Settings for each system type";
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
                    description = "Settings that a child project requests to be applied to its parent project";
                    type = types.deferredModule;
                    default = { };
                  };
                  rootProjectSettings = lib.mkOption {
                    description = ''
                      Settings that a child project requests to be applied to the root project.
                      Note: If this project _is_ the root project, these settings will not be applied to the project itself, only
                      child projects' `rootProjectSettings` will be applied.
                    '';
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
          description = ''
            An attribute set of child projects where each attribute set is itself a project.

            `defaultSettings` from this project are applied to all child projects, and child projects'
            `parentProjectSettings` are applied to this project.
          '';
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
          visible = "shallow";
        };
        tools = lib.mkOption {
          description = ''
            An list of tools to be used by this project. This is typically included in
            the `nativeCheckInputs` of the project's package, or `nativeBuildInputs` of a devShell.
          '';
          type = types.attrsOf (types.listOf types.package);
          readOnly = true;
          default = lib.mapAttrs (_system: perSystemSettings: perSystemSettings.tools.all) config.settings;
          defaultText = lib.literalMD "perSystemSettings.tools.all";
        };
      };
    };
in
projectModule
