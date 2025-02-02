# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  ...
}:
let
  inherit (lib) types;
  cfg = config.mkDerivation;
in
{
  options = {
    mkDerivation = {
      enable = lib.mkEnableOption "Enable creating a package with mkDerivation";
      stdenv = lib.mkOption {
        type = types.str;
        default = "stdenv";
      };
      args = lib.mkOption {
        readOnly = true;
        type = types.attrsOf types.raw;
        default = {
          inherit (config) name;
        } // cfg.extraArgs;
      };
      extraArgs = lib.mkOption {
        type = types.attrsOf types.raw;
        default = { };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    callPackageFunction = { pkgs, ... }: pkgs.${cfg.stdenv}.mkDerivation cfg.args;
  };
}
