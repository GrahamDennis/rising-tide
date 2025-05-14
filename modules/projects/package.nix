# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{
  config,
  pkgs,
  ...
}:
let
  inherit (lib) types;
in
{
  options = {
    callPackageFunction = lib.mkOption {
      type = types.nullOr risingTideLib.types.callPackageFunction;
      default = null;
    };
    package = lib.mkOption {
      type = types.nullOr types.package;
      default = null;
      defaultText = lib.literalExpression "A package";
    };
  };
  config = lib.mkIf (config.callPackageFunction != null) {
    overlay = risingTideLib.mkOverlay config.fullyQualifiedPackagePath config.callPackageFunction;
    package = lib.getAttrFromPath config.fullyQualifiedPackagePath pkgs;
    packages.${config.packageName} = config.package;
    mkShell.inputsFrom = [ config.package ];
    mkShell.enable = lib.mkIf config.package.meta.broken (lib.mkForce false);
  };
}
