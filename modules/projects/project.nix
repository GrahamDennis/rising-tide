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
      imports =
        (injector.injectModules [
          ./conventions
          ./devShells.nix
          ./mkShell.nix
          ./languages
          ./packages.nix
          ./tools
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
        absolutePath = lib.mkOption {
          description = "The absolute path to the project";
          type = types.path;
        };
        subprojects = lib.mkOption {
          description = ''
            An attribute set of child projects where each attribute set is itself a project.
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
                    { name, config, ... }:
                    {
                      inherit name;
                      relativePaths.parentProjectToRoot = parentProjectConfig.relativePaths.toRoot;
                      absolutePath = lib.path.append parentProjectConfig.absolutePath config.relativePaths.toParentProject;
                    }
                  )
                ];
            }
          );
          default = { };
          visible = "shallow";
        };

        subprojectsList = lib.mkOption {
          readOnly = true;
          type = types.listOf types.attrs;
          default = builtins.concatMap (subprojectConfig: subprojectConfig.allProjectsList) (
            builtins.attrValues config.subprojects
          );
          defaultText = lib.literalMD "a list containing all subproject configurations recursively.";
        };

        allProjectsList = lib.mkOption {
          readOnly = true;
          type = types.listOf types.attrs;
          default = config.subprojectsList ++ [ config ];
          defaultText = lib.literalMD "a list containing this project's configuration and subproject configurations recursively.";
        };

        allTools = lib.mkOption {
          description = ''
            An list of tools to be used by this project. This is typically included in
            the `nativeCheckInputs` of the project's package, or `nativeBuildInputs` of a devShell.
          '';
          type = types.listOf types.package;
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
