# rising-tide flake context
{
  lib,
  ...
}:
# project context
{ config, ... }:
let
  inherit (lib) types;
  cfg = config.languages.python.buildPythonPackage;
in
{
  options.languages.python.buildPythonPackage = {
    enable = lib.mkEnableOption "Create python package with buildPythonPackage";

    args = lib.mkOption {
      type = types.deferredModuleWith {
        staticModules = [
          {
            freeformType = types.raw;
            options = {
              name = lib.mkOption {
                type = types.str;
                default = config.name;
              };
              pyproject = (lib.mkEnableOption "Build using pyproject.toml file") // {
                default = true;
              };
              src = lib.mkOption {
                type = types.nullOr types.pathInStore;
                default = null;
              };
              dependencies = lib.mkOption {
                type = types.listOf types.package;
                default = [ ];
              };
            };
          }
        ];
      };

      apply =
        modules: pythonPackages:
        (lib.evalModules {
          inherit modules;
          prefix = [ "buildPythonPackage" ];
          specialArgs = { inherit pythonPackages; };
        }).config;
    };
  };

  config = lib.mkIf cfg.enable {
    languages.python.callPackageFunction =
      { pythonPackages, ... }: pythonPackages.buildPythonPackage cfg.args;
  };
}
