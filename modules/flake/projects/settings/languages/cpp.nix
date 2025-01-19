# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{ ... }:
{
  options = {
    settings = {
      languages.cpp = {
        enable = lib.mkEnableOption "Enable C++ package configuration";
        callPackageFunction = lib.mkOption {
          description = ''
            The function to call to build the C++ package. This is expected to be called like:

            ```
            pkgs.callPackage callPackageFunction {}
            ```
          '';
          type = risingTideLib.types.callPackageFunction;
        };
      };
    };
  };
}
