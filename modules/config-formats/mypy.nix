# rising-tide flake context
{ lib, ... }:
# mypy config context
{ config, ... }:
let
  inherit (lib) types;
  inherit (config) pkgs;
  settingsFormat = pkgs.formats.toml { };
in
{
  options = {
    data = lib.mkOption {
      description = ''
        The mypy TOML file to generate. All configuration here is nested under the `tool.mypy` key
        in the generated file.

        Refer to the [mypy documentation](https://mypy.readthedocs.io/en/stable/config_file.html),
        in particular the [pyproject.toml format documentation](https://mypy.readthedocs.io/en/stable/config_file.html#using-a-pyproject-toml-file).
      '';
      type = settingsFormat.type;
      default = { };
    };
    perModuleOverrides = lib.mkOption {
      description = ''
        An attrset of overrides where the key of the attrset is the module that the override is for.
      '';
      type = types.attrsOf (settingsFormat.type);
      default = { };
      example = {
        "mycode.foo.*" = {
          disallow_untyped_defs = false;
        };
      };
    };
    configFile = lib.mkOption {
      default = settingsFormat.generate "mypy.toml" { tool.mypy = config.data; };
    };
  };
  config = {
    data.overrides = lib.mkIf (config.perModuleOverrides != { }) (
      lib.mapAttrsToList (module: override: override // { inherit module; }) config.perModuleOverrides
    );
  };
}
