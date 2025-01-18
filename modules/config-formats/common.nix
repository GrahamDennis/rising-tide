# rising-tide flake context
{
  lib,
  inputs,
  ...
}:
# mypy config context
{
  system,
  ...
}:
let
  inherit (lib) types;
  _pkgs = inputs.nixpkgs.legacyPackages.${system};
in
{
  options = {
    pkgs = lib.mkOption {
      type = types.pkgs;
      description = "The package set to use for config file generation";
      default = _pkgs;
    };
    configFile = lib.mkOption {
      description = "Generated config file";
      type = types.pathInStore;
    };
  };
}
