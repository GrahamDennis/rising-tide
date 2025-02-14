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
  options = {
    namespacePath = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    packageName = lib.mkOption {
      type = types.str;
      default = config.name;
    };
    fullyQualifiedPackagePath = lib.mkOption {
      readOnly = true;
      type = types.listOf types.str;
      default = config.namespacePath ++ [ config.packageName ];
    };
    subprojects = lib.mkOption {
      type = types.attrsOf (
        types.submodule {
          # Children inherit the namespace path of their parent
          namespacePath = lib.mkDefault config.namespacePath;
        }
      );
    };
  };
}
