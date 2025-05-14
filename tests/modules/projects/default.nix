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
        relativePaths.fromRoot = ".";
      }
      {
        name = "my-awesome-project";
        relativePaths.fromRoot = "./.";
        relativePaths.toRoot = ".";
        enabledSubprojectsList = [ ];
      };
  "test project with path to parent" =
    expectRenderedConfig
      {
        relativePaths.parentProjectFromRoot = ".";
        relativePaths.fromParentProject = "my-awesome-project";
      }
      {
        relativePaths.fromRoot = "./my-awesome-project";
        relativePaths.parentProjectFromRoot = "./.";
        relativePaths.fromParentProject = "./my-awesome-project";
      };

  "test single subproject" =
    expectRenderedConfig
      {
        name = "root";
        relativePaths.fromRoot = ".";
        subprojects.subproject.relativePaths.fromParentProject = "./subproject";
      }
      {
        name = "root";
        relativePaths.fromRoot = "./.";
        subprojects.subproject = {
          name = "subproject";
          relativePaths = {
            fromRoot = "./subproject";
            parentProjectFromRoot = "./.";
            fromParentProject = "./subproject";
          };
        };
      };

}
