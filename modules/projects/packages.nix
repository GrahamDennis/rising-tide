# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
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
    (lib.mkIf (config.isRootProject) {
      packages._all-project-packages = toolsPkgs.linkFarm "all-project-packages" (
        builtins.removeAttrs config.packages [ "_all-project-packages" ]
      );
      tools.go-task.taskfile.tasks.build.deps = [ "nix-build:_all-project-packages" ];
    })
  ];
}
