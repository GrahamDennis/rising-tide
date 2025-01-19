# rising-tide flake context
{
  injector,
  lib,
  risingTideLib,
  withSystem,
  ...
}:
let
  inherit (lib) types;
  projectModule =
    # project context
    {
      config,
      system,
      projectModules,
      ...
    }:
    {
      _file = ./project.nix;

      imports =
        (injector.injectModules [
          ./settings
        ])
        ++ projectModules;

      options = {
        name = lib.mkOption {
          description = "The name of the project";
          type = types.str;
          example = "my-project";
        };
        isRootProject = lib.mkOption {
          description = "Whether this is the root project";
          type = types.bool;
          readOnly = true;
          default = config.relativePaths.toRoot == "./.";
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
        settings = lib.mkOption {
          description = "Settings for the project";
          type =
            let
              projectConfig = config;
            in
            types.submoduleWith ({
              modules = [
                {
                  imports =
                    # Apply parent project settings from child projects (child projects may not support the same systems as the parent)
                    (lib.mapAttrsToList (
                      _subprojectName: subprojectConfig: subprojectConfig.parentProjectSettings
                    ) projectConfig.subprojects)
                    # Apply root project settings from child projects if this is the root project
                    ++ (lib.optional (projectConfig.relativePaths.toRoot == "./.") (projectConfig.rootProjectSettings));
                  config = {
                    # FIXME: Can this be removed?
                    _module.args = {
                      inherit system;
                      inherit (config) toolsPkgs;
                      project = {
                        inherit (config) relativePaths name;
                      };
                    };
                  };
                }
              ];
            });
          default = { };
        };
        parentProjectSettings = lib.mkOption {
          description = "Settings that a child project requests to be applied to its parent project";
          type = types.deferredModule;
          default = { };
        };
        rootProjectSettings = lib.mkOption {
          description = ''
            Settings that a child project requests to be applied to the root project.
          '';
          type = types.deferredModuleWith {
            staticModules = lib.mapAttrsToList (
              _subprojectName: subprojectConfig: subprojectConfig.rootProjectSettings
            ) config.subprojects;
          };
          default = { };
        };
        subprojects = lib.mkOption {
          description = ''
            An attribute set of child projects where each attribute set is itself a project.

            Child projects' `parentProjectSettings` are applied to this project.
          '';
          type = types.attrsOf (
            types.submoduleWith {
              specialArgs = { inherit system projectModules; };
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
                    }
                  )
                ];
            }
          );
          default = { };
          visible = "shallow";
        };
        allTools = lib.mkOption {
          description = ''
            An list of tools to be used by this project. This is typically included in
            the `nativeCheckInputs` of the project's package, or `nativeBuildInputs` of a devShell.
          '';
          type = (types.listOf types.package);
          default = [ ];
        };
        toolsPkgs = lib.mkOption {
          description = ''
            The nixpkgs package set to be used by project tooling, e.g. shellcheck, ruff, mypy, etc.
            This package set does not need to be the same as is used for building the project itself, to permit
            newer tooling to be used with projects building against older versions of nixpkgs.
          '';
          type = types.pkgs;
          default = withSystem system ({ pkgs, ... }: pkgs);
          defaultText = lib.literalMD "`pkgs` defined by rising-tide";
        };
      };
      config = {
        _module.args = {
          toolsPkgs = config.toolsPkgs;
        };
      };
    };
in
projectModule
