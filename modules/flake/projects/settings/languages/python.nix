# rising-tide flake context
{
  lib,
  risingTideLib,
  flake-parts-lib,
  ...
}:
# project context
{ config, ... }:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.languages.python;
in
{
  options = {
    settings = mkSubmoduleOptions {
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
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      settings = {
        languages.python.pythonOverlay = ifEnabled (
          lib.mkDefault (
            python-final: _python-prev: {
              ${config.name} = python-final.callPackage cfg.callPackageFunction { };
            }
          )
        );

      };
      parentProjectSettings.languages.python.pythonOverlay = ifEnabled cfg.pythonOverlay;
    };
}
