{lib, risingTideBootstrapLib, self, ...}: 
  let
  inherit (lib) types;
  in
risingTideBootstrapLib // {
  mkProject = projectModule: (lib.evalModules { modules = [ self.flakeModules.project projectModule { relativePaths.toRoot = lib.mkDefault "./."; } ]; class = "projectConfig"; }).config;
  types = {
    subpath = types.str // {
      name = "subpath";
      description = "A relative path";
      merge = loc: defs: lib.path.subpath.normalise (lib.mergeEqualOption loc defs);
    };
  };
}