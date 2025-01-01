# rising-tide flake context
{
  lib,
  self,
  ...
}: let
  projectModule = self.flakeModules.project;
  expectRenderedConfig = module: expected: let
    expr =
      (lib.evalModules {
        modules = [projectModule module];
        class = "projectConfig";
      })
      .config;
  in {
    inherit expr expected;
  };
in {
  "test simple evaluation" =
    expectRenderedConfig {
      name = "my-awesome-project";
      relativePaths.toRoot = ".";
    } {
      name = "my-awesome-project";
      relativePaths.toRoot = "./.";
      relativePaths.parentProjectToRoot = null;
      relativePaths.toParentProject = null;
    };
  "test child project evaluation" =
    expectRenderedConfig {
      name = "my-awesome-project";
      relativePaths.parentProjectToRoot = ".";
      relativePaths.toParentProject = "my-awesome-project";
    } {
      name = "my-awesome-project";
      relativePaths.toRoot = "./my-awesome-project";
      relativePaths.parentProjectToRoot = "./.";
      relativePaths.toParentProject = "./my-awesome-project";
    };
}
