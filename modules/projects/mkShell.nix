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
      defaultText = lib.literalExpression "config.name";
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
      defaultText = lib.literalMD "A `pkgs.mkShell` package";
    };
  };
  config = {
    mkShell = lib.mkMerge [
      {
        nativeBuildInputs = config.allTools;
      }
      {
        inputsFrom = builtins.concatMap (
          projectConfig: projectConfig.mkShell.inputsFrom
        ) config.subprojectsList;
        nativeBuildInputs = builtins.concatMap (
          projectConfig: projectConfig.mkShell.nativeBuildInputs
        ) config.subprojectsList;
      }
    ];
  };
}
