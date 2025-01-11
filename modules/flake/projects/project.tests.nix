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

  "test systems are inherited" =
    expectRenderedConfig
      {
        name = "root";
        relativePaths.toRoot = ".";
        subprojects.subproject = {
          relativePaths.toParentProject = "./subproject";
        };
      }
      {
        name = "root";
        subprojects.subproject = {
          name = "subproject";
        };
      };

  "test subproject systems can be overridden" =
    expectRenderedConfig
      {
        name = "root";
        relativePaths.toRoot = ".";
        subprojects.subproject = {
          relativePaths.toParentProject = "./subproject";
        };
      }
      {
        name = "root";
        subprojects.subproject = {
          name = "subproject";
        };
      };

  "test default settings are inherited" =
    expectRenderedConfig
      {
        name = "root";
        relativePaths.toRoot = ".";
        defaultSettings.tools.treefmt.enable = true;
        subprojects.subproject = {
          relativePaths.toParentProject = "./subproject";
        };
      }
      {
        name = "root";
        settings.tools.treefmt.enable = true;
        subprojects.subproject = {
          name = "subproject";
          settings.tools.treefmt.enable = true;
        };
      };

}
