# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{ config, pkgs, ... }:
let
  inherit (lib) types;
  getCfg = projectConfig: projectConfig.languages.python;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
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

      pythonPackages = lib.mkOption {
        type = types.attrs;
        default = pkgs.python3.pkgs;
        defaultText = lib.literalExpression ''pkgs.python3.pkgs'';
      };

      package = lib.mkOption {
        type = types.package;
        default = cfg.pythonPackages.${config.name};
        defaultText = lib.literalExpression "config.languages.python.pythonPackages.\${config.name}";
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
      languages.python.pythonOverlay = lib.mkDefault (
        python-final: _python-prev: {
          # FIXME: It should be possible to configure the output name separately from subproject
          # name as this is part of the API of the package
          ${config.name} = python-final.callPackage cfg.callPackageFunction { };
        }
      );
      mkShell.inputsFrom = [ cfg.package ];
    })
    (lib.mkIf config.isRootProject {
      languages.python.pythonOverlay = lib.mkMerge (
        builtins.map (subprojectConfig: (getCfg subprojectConfig).pythonOverlay) (
          builtins.filter enabledIn config.subprojectsList
        )
      );
    })
  ];
}
