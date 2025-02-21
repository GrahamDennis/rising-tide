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
          # keep-sorted start
          ./conventions
          ./devShells.nix
          ./hydraJobs.nix
          ./languages
          ./mkShell.nix
          ./namespace.nix
          ./overlay.nix
          ./package.nix
          ./packages.nix
          ./tasks.nix
          ./tools
          # keep-sorted end
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
          # FIXME: The name is wrong, this should be fromRoot not toRoot
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
          # This should be fromParentProject
          toParentProject = lib.mkOption {
            description = "The path from the project to the parent project";
            type = risingTideLib.types.subpath;
            default = config.name;
            defaultText = lib.literalMD "The name of this project: `\${config.name}`";
          };
          # This should be rootToParentProject or parentProjectFromRoot
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
              shorthandOnlyDefinesConfig = true;
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
