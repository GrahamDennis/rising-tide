# rising-tide context
{
  injector,
  lib,
  ...
}:
let
  inherit (lib) types;
in
# project settings context
{ config, ... }:
{
  imports = injector.injectModules [ ./tools ];
  options = {
    pkgs = lib.mkOption {
      description = "the pkgs to be used by generated packages";
      type = types.pkgs;
    };
  };
  config = {
    _module.args.pkgs = config.pkgs;
  };
}
