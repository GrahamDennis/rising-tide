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
  options.hydraJobs = lib.mkOption {
    type = recursivePackagesType;
    default = { };
  };
  config = {
    hydraJobs = lib.pipe config.packages [
      (lib.flip builtins.removeAttrs [ "_all-project-packages" ])
      (builtins.mapAttrs (_name: package: lib.hydraJob package))
    ];
  };
}
