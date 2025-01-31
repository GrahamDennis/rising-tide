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
  options.devShells = lib.mkOption {
    type = types.attrsOf types.package;
    default = { };
  };
  config = lib.mkMerge [
    {
      devShells.default = lib.mkIf config.mkShell.enable config.mkShell.package;
    }
    {
      devShells = builtins.listToAttrs (
        lib.pipe config.subprojectsList [
          (builtins.filter (subproject: subproject.mkShell.enable))
          # FIXME: Using the path here is wrong. It should be a logical path from subproject names.
          # For example if all subprojects live in projects/, then devShells shouldn't contain `projects/`
          # in their names.
          # And if it's a logical path, it shouldn't use `/` as the separator but `.` or `:`.
          (builtins.map (
            subproject:
            lib.nameValuePair (lib.removePrefix "./" subproject.relativePaths.toRoot) subproject.mkShell.package
          ))
        ]
      );
    }
  ];
}
