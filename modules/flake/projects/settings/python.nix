# rising-tide flake context
{ lib, risingTideLib, ... }:
# project settings context
{ config, project, ... }:
let
  cfg = config.python;
in
{
  options = {
    python = {
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
    };
  };

  config = lib.mkIf cfg.enable {
    python.pythonOverlay = lib.mkDefault (
      python-final: _python-prev: {
        ${project.name} = python-final.callPackage cfg.callPackageFunction { };
      }
    );

    parentProjectSettings.python.pythonOverlay = cfg.pythonOverlay;
  };
}
