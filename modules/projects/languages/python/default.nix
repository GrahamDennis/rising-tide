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
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  getCfg = projectConfig: projectConfig.languages.python;
  cfg = getCfg config;
  pyprojectSettingsFormat = toolsPkgs.formats.toml { };
  pyprojectConfigFile = pyprojectSettingsFormat.generate "pyproject.toml" cfg.pyproject;
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
        type = risingTideLib.types.callPackageFunction;
      };

      pyproject = lib.mkOption {
        description = "Contents of a pyproject.toml file to generate";
        type = pyprojectSettingsFormat.type;
        default = { };
      };

      pyprojectFile = lib.mkOption {
        type = types.pathInStore;
        default = pyprojectConfigFile;
      };

      pythonPackages = lib.mkOption {
        type = types.attrs;
        default = pkgs.python3.pkgs;
        defaultText = lib.literalExpression ''pkgs.python3.pkgs'';
      };

      package = lib.mkOption {
        type = types.package;
        defaultText = lib.literalMD "The python package extracted from config.languages.python.pythonPackages";
      };

      pythonOverlay = lib.mkOption {
        description = ''
          A python overlay that contains the python package.


          This can be applied to a python package like so ([see documentation](https://nixos.org/manual/nixpkgs/stable/#how-to-override-a-python-package-using-overlays)):

          ```
          python.override { packageOverrides = pythonOverlay; };
          ```

          Or to all python packages in a pkgs by creating a nixpkgs overlay like so ([see documentation](https://nixos.org/manual/nixpkgs/stable/#how-to-override-a-python-package-for-all-python-versions-using-extensions)):

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
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      languages.python.pythonOverlay = risingTideLib.mkOverlay config.fullyQualifiedPackagePath cfg.callPackageFunction;
      languages.python.package = lib.getAttrFromPath config.fullyQualifiedPackagePath cfg.pythonPackages;
      mkShell.inputsFrom = [ cfg.package ];
      packages.${config.packageName} = cfg.package;
    })
    # Inherit parent python overlays
    {
      languages.python.pythonOverlay = lib.mkMerge (
        lib.pipe config.subprojects [
          builtins.attrValues
          (builtins.map (subprojectConfig: (getCfg subprojectConfig).pythonOverlay))
        ]
      );
    }
    (lib.mkIf config.isRootProject {
      overlay = _final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [ cfg.pythonOverlay ];
      };
    })
  ];
}
