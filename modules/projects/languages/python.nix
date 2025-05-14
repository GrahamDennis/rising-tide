# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{
  config,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  getCfg = projectConfig: projectConfig.languages.python;
  pythonEnabledIn = projectConfig: (getCfg projectConfig).enable;
  cfg = getCfg config;
in
{
  options = {
    languages.python = {
      enable = lib.mkEnableOption "Enable python package configuration";
      callPackageFunction = lib.mkOption {
        description = ''
          The function to call to build the python package. This is expected to be called like:

          ```
          pythonPackages.callPackage callPackageFunction {}
          ```
        '';
        type = types.nullOr risingTideLib.types.callPackageFunction;
        default = null;
      };

      pythonNamespacePath = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      fullyQualifiedPackagePath = lib.mkOption {
        readOnly = true;
        type = types.listOf types.str;
        default = cfg.pythonNamespacePath ++ [ config.packageName ];
      };

      pythonPackages = lib.mkOption {
        type = types.attrs;
        default = pkgs.python3.pkgs;
        defaultText = lib.literalExpression ''pkgs.python3.pkgs'';
      };

      package = lib.mkOption {
        type = types.nullOr types.package;
        default = null;
      };

      pythonOverlay = lib.mkOption {
        description = ''
          A python overlay that contains the python package.


          This can be applied to a python package like so
          ([see documentation](https://nixos.org/manual/nixpkgs/stable/#how-to-override-a-python-package-using-overlays)):

          ```
          python.override { packageOverrides = pythonOverlay; };
          ```

          Or to all python packages in a pkgs by creating a nixpkgs overlay like so
          ([see documentation](https://nixos.org/manual/nixpkgs/stable/#how-to-override-a-python-package-for-all-python-versions-using-extensions)):

          ```
          nixpkgsOverlay = _final: prev: {
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [ pythonOverlay ];
          };
          ```
        '';
        type = risingTideLib.types.overlay;
        default = _final: _prev: { };
      };

      sourceRoots = lib.mkOption {
        description = ''Project subpaths that contain python source'';
        type = types.listOf risingTideLib.types.subpath;
        default = [ "src" ];
      };

      testRoots = lib.mkOption {
        description = ''Project subpaths that contain python test sources'';
        type = types.listOf risingTideLib.types.subpath;
        default = [ "tests" ];
      };
    };
    subprojects = lib.mkOption {
      type = types.attrsOf (
        types.submodule {
          # Children inherit the namespace path of their parent
          languages.python.pythonNamespacePath = lib.mkDefault cfg.pythonNamespacePath;
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.callPackageFunction != null) {
      languages.python.pythonOverlay = risingTideLib.mkOverlay cfg.fullyQualifiedPackagePath cfg.callPackageFunction;
      languages.python.package = lib.getAttrFromPath cfg.fullyQualifiedPackagePath cfg.pythonPackages;
      packages.${config.packageName} = cfg.package;
    })
    (lib.mkIf (cfg.enable && (lib.isDerivation cfg.package) && cfg.package.meta.broken) {
      # Disable broken packages
      enable = lib.mkForce false;
    })
    (lib.mkIf cfg.enable {
      mkShell.enable = true;
      mkShell.inputsFrom = [ cfg.package ];
    })
    # Inherit parent python overlays
    {
      languages.python.pythonOverlay = lib.mkMerge (
        (builtins.map (subprojectConfig: (getCfg subprojectConfig).pythonOverlay)) config.subprojectsList
      );
    }
    (lib.mkIf config.isRootProject {
      # FIXME: This may need to be able to be overridden
      overlay = _final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [ cfg.pythonOverlay ];
      };
      tools.jetbrains =
        let
          inherit (cfg.pythonPackages.python) pythonVersion;
          # This "JDK" name depends on the name of the directory containing this project.
          # The @projectDirName@ variable will get rewritten when the file is written.
          sdkName = "Python ${pythonVersion} (@projectDirName@)";
        in
        lib.mkIf (builtins.any pythonEnabledIn config.allProjectsList) {
          projectSettings = {
            "misc.xml" = {
              components.Black.options = { inherit sdkName; };
              components.ProjectRootManager.attrs = {
                version = "2";
                project-jdk-name = sdkName;
                project-jdk-type = "Python SDK";
              };
            };
            "modules.xml" = {
              components.ProjectModuleManager.children = [
                {
                  name = "modules";
                  children = [
                    {
                      name = "module";
                      attrs.fileurl = "file://$PROJECT_DIR$/.idea/${config.name}.iml";
                      attrs.filepath = "$PROJECT_DIR$/.idea/${config.name}.iml";
                    }
                  ];
                }
              ];
            };
          };
          moduleSettings."${config.name}.iml" = {
            type = "PYTHON_MODULE";
            root = {
              contentEntries = [
                {
                  url = "file://$MODULE_DIR$";
                  sourceFolders = lib.pipe config.allProjectsList [
                    (builtins.filter pythonEnabledIn)
                    (builtins.concatMap (
                      projectConfig:
                      (builtins.map (srcRoot: {
                        url = "file://$MODULE_DIR$/${projectConfig.relativePaths.fromRoot}/${srcRoot}";
                        isTestSource = false;
                      }) (getCfg projectConfig).sourceRoots)
                      ++ (builtins.map (testRoot: {
                        url = "file://$MODULE_DIR$/${projectConfig.relativePaths.fromRoot}/${testRoot}";
                        isTestSource = true;
                      }) (getCfg projectConfig).testRoots)
                    ))
                  ];
                  excludeFolders = [
                    { url = "file://$MODULE_DIR$/.venv"; }
                  ];
                }
              ];
              orderEntries = [
                {
                  type = "jdk";
                  attrs = {
                    jdkType = "Python SDK";
                    jdkName = sdkName;
                  };
                }
                {
                  type = "sourceFolder";
                  attrs.forTests = "false";
                }
              ];
            };
            components = {
              PyDocumentationSettings.options = {
                format = "PLAIN";
                myDocStringFormat = "Plain";
              };
              TestRunnerService.options.PROJECT_TEST_RUNNER = "py.test";
            };
          };
        };
    })
  ];
}
