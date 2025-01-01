# rising-tide flake context
{lib, withSystem, ...}:
# project per-system tools context
{system, ...}:
{ config = {
  # the pkgs to be used by tools
  _module.args.pkgs = lib.mkOptionDefault (withSystem system ({pkgs, ...}: pkgs));
};}