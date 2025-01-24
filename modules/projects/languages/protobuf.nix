# rising-tide flake context
{
  lib,
  ...
}:
# project context
{ ... }:
{
  options = {
    languages.protobuf = {
      enable = lib.mkEnableOption "Enable protobuf language configuration";
    };
  };
}
