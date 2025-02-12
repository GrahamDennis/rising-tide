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
  recursivePackagesType = types.attrsOf (
    types.oneOf [
      types.bool
      types.package
      recursivePackagesType
    ]
  );
in
{
  options.nix-eval-jobs = lib.mkOption {
    type = recursivePackagesType;
    default = { };
  };
  config = {
    nix-eval-jobs = builtins.removeAttrs config.packages [ "_all-project-packages" ];
  };
}
