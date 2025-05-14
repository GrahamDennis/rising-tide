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
          ./legacyPackages.nix
          ./mkShell
          ./namespace.nix
          ./overlay.nix
          ./package.nix
          ./packages.nix
          ./tasks
          ./tools
          # keep-sorted end
        ])
        ++ projectModules;

      options = {
        enable = lib.mkOption {
          type = types.bool;
          description = "Whether the subproject is enabled";
          default = true;
        };
        name = lib.mkOption {
          description = "The name of the project";
          type = types.str;
          example = "my-project";
        };
        isRootProject = lib.mkOption {
          description = "Whether this is the root project";
          type = types.bool;
          readOnly = true;
          default = config.relativePaths.fromRoot == "./.";
        };
        relativePaths = {
          # FIXME: The name is wrong, this should be fromRoot not fromRoot
          fromRoot = lib.mkOption {
            description = "The path from the project to the root of the flake";
            type = risingTideLib.types.subpath;
            default = lib.path.subpath.join [
              config.relativePaths.parentProjectFromRoot
              config.relativePaths.fromParentProject
            ];
            defaultText = lib.literalExpression ''
              lib.path.subpath.join [
                config.relativePaths.parentProjectFromRoot
                config.relativePaths.fromParentProject
              ]
            '';
          };
          # This should be fromParentProject
          fromParentProject = lib.mkOption {
            description = "The path from the project to the parent project";
            type = risingTideLib.types.subpath;
            default = config.name;
            defaultText = lib.literalMD "The name of this project: `\${config.name}`";
          };
          # This should be rootToParentProject or parentProjectFromRoot
          parentProjectFromRoot = lib.mkOption {
            description = "The path from the parent project to the root of the flake";
            type = risingTideLib.types.subpath;
            readOnly = true;
          };
          toRoot = lib.mkOption {
            readOnly = true;
            type = types.str;
            default = lib.pipe config.relativePaths.fromRoot [
              lib.path.subpath.components
              (builtins.map (_: ".."))
              (components: if (builtins.length components) == 0 then [ "." ] else components)
              (builtins.concatStringsSep "/")
            ];
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
                      relativePaths.parentProjectFromRoot = parentProjectConfig.relativePaths.fromRoot;
                      absolutePath = lib.path.append parentProjectConfig.absolutePath config.relativePaths.fromParentProject;
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
          default = lib.pipe config.subprojects [
            builtins.attrValues
            (builtins.filter (subprojectConfig: subprojectConfig.enable))
            (builtins.concatMap (subprojectConfig: subprojectConfig.allProjectsList))
          ];
          defaultText = lib.literalMD "a list containing all subproject configurations recursively.";
        };

        allProjectsList = lib.mkOption {
          readOnly = true;
          type = types.listOf types.attrs;
          default = lib.mkMerge [
            config.subprojectsList
            (lib.mkIf config.enable)
          ];
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
