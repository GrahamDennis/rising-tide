# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  pkgs,
  ...
}:
let
  inherit (lib) types;
in
{
  options.legacyPackages = lib.mkOption {
    type = types.lazyAttrsOf types.raw;
    default = { };
  };
  config = {
    legacyPackages = pkgs;
  };
}
