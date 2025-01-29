# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.mkShell;
in
{
  options.mkShell = {
    enable = (lib.mkEnableOption "Create a dev shell for this project") // {
      default = cfg.inputsFrom != [ ];
    };
    name = lib.mkOption {
      type = types.str;
      default = config.name;
    };
    stdenv = lib.mkOption {
      type = types.str;
      default = "stdenv";
    };
    inputsFrom = lib.mkOption {
      type = types.listOf types.package;
      default = [ ];
    };
    nativeBuildInputs = lib.mkOption {
      type = types.listOf types.package;
      default = [ ];
    };
    package = lib.mkOption {
      type = types.package;
      default = (toolsPkgs.mkShell.override { stdenv = toolsPkgs.${cfg.stdenv}; }) {
        inherit (cfg) name inputsFrom nativeBuildInputs;
      };
    };
  };
  config = {
    mkShell = {
      nativeBuildInputs = builtins.concatMap (
        projectConfig: projectConfig.allTools
      ) config.allProjectsList;
    };
  };
}
