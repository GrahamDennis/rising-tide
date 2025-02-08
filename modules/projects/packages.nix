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
in
{
  options.packages = lib.mkOption {
    type = types.attrsOf types.package;
    default = { };
  };
  config = lib.mkMerge [
    {
      packages = lib.mkMerge (
        lib.pipe config.subprojects [
          builtins.attrValues
          (builtins.map (subproject: subproject.packages))
        ]
      );
    }
  ];
}
