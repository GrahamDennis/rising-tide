# rising-tide flake context
{ lib, risingTideLib, ... }:
# project settings context
{ config, ... }:
let
  inherit (lib) types;
  cfg = config.python;
in
{
  options = {
    python = {
      enable = lib.mkEnableOption "Enable python package configuration";
      callPackageFunction = lib.mkOption {
        type = risingTideLib.types.callPackageFunction;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      uv.enable = true;
    };
  };
}
