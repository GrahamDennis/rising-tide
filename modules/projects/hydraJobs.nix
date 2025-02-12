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
  recursivePackagesType = (
    types.attrsOf (
      types.oneOf [
        types.bool
        types.package
        recursivePackagesType
      ]
    )
    // {
      description = "Nested Hydra jobs";
    }
  );
in
{
  options.hydraJobs = lib.mkOption {
    type = recursivePackagesType;
    default = { };
    description = "Jobs to be evaluated (and built) using nix-eval-jobs or similar.";
  };
  config = {
    hydraJobs = lib.pipe config.packages [
      (lib.flip builtins.removeAttrs [ "_all-project-packages" ])
      (builtins.mapAttrs (_name: package: lib.hydraJob package))
    ];
  };
}
