# rising-tide flake context
{lib, self, ...}: let
  projectModule = self.flakeModules.project;
  expectRenderedConfig = module: expected: let
    expr = (lib.evalModules {
      modules = [ projectModule module ];
      class = "projectConfig";
    }).config;
  in {
    inherit expr expected;
  };
in {
  "test simple evaluation" = expectRenderedConfig { name = "my-awesome-project"; relativePaths.toRoot = ".";} {
    name = "my-awesome-project"; relativePaths.toRoot = "./.";
  };
}
