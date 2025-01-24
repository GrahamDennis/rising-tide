# rising-tide flake context
{
  lib,
  self,
  risingTideLib,
  ...
}:
let
  projectModule = self.modules.flake.project;
  defaults = {
    name = lib.mkDefault "default-project-name";
  };
  expectRenderedConfig = risingTideLib.tests.mkExpectRenderedConfig {
    modules = [
      projectModule
      defaults
    ];
    specialArgs = {
      system = "example-system";
      projectModules = [ ];
    };
  };
in
{
  "test simple evaluation" =
    expectRenderedConfig
      {
        name = "my-awesome-project";
        relativePaths.toRoot = ".";
      }
      {
        name = "my-awesome-project";
        relativePaths.toRoot = "./.";
        subprojectsList = [ ];
        allTools = [ ];
      };
  "test project with path to parent" =
    expectRenderedConfig
      {
        relativePaths.parentProjectToRoot = ".";
        relativePaths.toParentProject = "my-awesome-project";
      }
      {
        relativePaths.toRoot = "./my-awesome-project";
        relativePaths.parentProjectToRoot = "./.";
        relativePaths.toParentProject = "./my-awesome-project";
      };

  "test single subproject" =
    expectRenderedConfig
      {
        name = "root";
        relativePaths.toRoot = ".";
        subprojects.subproject.relativePaths.toParentProject = "./subproject";
      }
      {
        name = "root";
        relativePaths.toRoot = "./.";
        subprojects.subproject = {
          name = "subproject";
          relativePaths = {
            toRoot = "./subproject";
            parentProjectToRoot = "./.";
            toParentProject = "./subproject";
          };
        };
      };

}
