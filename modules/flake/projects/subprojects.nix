# rising-tide flake context
{ lib, self, ... }: let 
  inherit (lib) types;
  projectModule = self.modules.flake.project;
in
# user flake context
{ ... }: {
  options = {
    subprojects = lib.mkOption {
      type = types.attrsOf (types.submoduleWith {
        modules = [projectModule];
      });
      default = {};
    };
  };
}