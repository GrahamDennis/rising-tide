# rising-tide flake context
{ lib, risingTideLib, ... }:
# project settings context
{ ... }:
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
    };
  };
}
