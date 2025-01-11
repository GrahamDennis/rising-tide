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
    { config, system, ... }:
    {
      _file = ./project.nix;

      imports = injector.injectModules [
        # languages
        ./settings/python.nix

        # tools
        ./settings/tools/alejandra.nix
        ./settings/tools/deadnix.nix
        ./settings/tools/go-task
        ./settings/tools/lefthook.nix
        ./settings/tools/mypy.nix
        ./settings/tools/nix-unit.nix
        ./settings/tools/nixago
        ./settings/tools/nixfmt-rfc-style.nix
        ./settings/tools/pytest.nix
        ./settings/tools/ruff.nix
        ./settings/tools/shellcheck.nix
        ./settings/tools/shfmt.nix
        ./settings/tools/treefmt.nix
        ./settings/tools/vscode.nix
      ];

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
        defaultSettings = lib.mkOption {
          description = ''
            `settings` configs that apply to this project and all nested subprojects.
            Project-wide or organisation-wide configuration should be set here (for example the rising-tide default conventions).
          '';
          type = types.deferredModule;
          default = { };
        };
        settings = lib.mkOption {
          description = "Settings for the project";
          type =
            let
              projectConfig = config;
              emptyChildProjectSettings = {
                parentProjectSettings = { };
                rootProjectSettings = { };
              };
            in
            types.submoduleWith ({
              modules = [
                {
                  imports =
                    [ (injector.injectModule ./settings) ]
                    # Apply default settings
                    ++ [ projectConfig.defaultSettings ]
                    # Apply parent project settings from child projects (child projects may not support the same systems as the parent)
                    ++ (lib.mapAttrsToList (
                      _subprojectName: subprojectConfig:
                      (subprojectConfig.settings or emptyChildProjectSettings).parentProjectSettings
                    ) projectConfig.subprojects)
                    # Apply root project settings from child projects if this is the root project
                    ++ (lib.optionals (projectConfig.relativePaths.toRoot == "./.") (
                      lib.mapAttrsToList (
                        _subprojectName: subprojectConfig:
                        (subprojectConfig.settings or emptyChildProjectSettings).rootProjectSettings
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
                          (subprojectConfig.settings or emptyChildProjectSettings).rootProjectSettings
                        ) projectConfig.subprojects;
                      };
                      default = { };
                    };
                  };
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
        subprojects = lib.mkOption {
          description = ''
            An attribute set of child projects where each attribute set is itself a project.

            `defaultSettings` from this project are applied to all child projects, and child projects'
            `parentProjectSettings` are applied to this project.
          '';
          type = types.attrsOf (
            types.submoduleWith {
              specialArgs = { inherit system; };
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
          type = (types.listOf types.package);
          readOnly = true;
          default = config.settings.tools.all;
          defaultText = lib.literalText "config.settings.tools.all";
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
