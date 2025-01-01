# rising-tide flake context
{
  lib,
  self,
  ...
}: let
  projectModule = self.modules.flake.project;
  expectRenderedConfig = module: expected: let
    expr =
      (lib.evalModules {
        modules = [projectModule module];
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
      subprojects = {};
    };
  "test child project evaluation" =
    expectRenderedConfig {
      name = "my-awesome-project";
      relativePaths.parentProjectToRoot = ".";
      relativePaths.toParentProject = "my-awesome-project";
      subprojects = {};
    } {
      name = "my-awesome-project";
      relativePaths.toRoot = "./my-awesome-project";
      relativePaths.parentProjectToRoot = "./.";
      relativePaths.toParentProject = "./my-awesome-project";
      subprojects = {};
    };
  
  "test single subproject" = expectRenderedConfig { name = "root"; relativePaths.toRoot = "."; subprojects.subproject.relativePaths.toParentProject="./subproject"; }
  {
    name = "root";
    relativePaths.toRoot = "./.";
    relativePaths.parentProjectToRoot = null;
    relativePaths.toParentProject = null;
    subprojects.subproject = {
        name = "subproject";
        relativePaths = {
          toRoot = "./subproject";
          parentProjectToRoot = "./.";
          toParentProject = "./subproject";
        };
        subprojects = {};
    };
  };
}
