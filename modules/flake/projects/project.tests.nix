# rising-tide flake context
{
  lib,
  self,
  risingTideLib,
  ...
}: let
  projectModule = self.modules.flake.project;
  defaults = {
    name = lib.mkDefault "default-project-name";
    systems = lib.mkDefault ["example-system"];
  };
  expectRenderedConfig = risingTideLib.tests.mkExpectRenderedConfig {modules = [projectModule defaults];};
in {
  "test simple evaluation" =
    expectRenderedConfig {
      name = "my-awesome-project";
      relativePaths.toRoot = ".";
    } {
      name = "my-awesome-project";
      relativePaths.toRoot = "./.";
    };
  "test project with path to parent" =
    expectRenderedConfig {
      relativePaths.parentProjectToRoot = ".";
      relativePaths.toParentProject = "my-awesome-project";
    } {
      relativePaths.toRoot = "./my-awesome-project";
      relativePaths.parentProjectToRoot = "./.";
      relativePaths.toParentProject = "./my-awesome-project";
    };

  "test single subproject" =
    expectRenderedConfig {
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
    expectRenderedConfig {
      name = "root";
      relativePaths.toRoot = ".";
      systems = ["x86_64-linux"];
      subprojects.subproject = {name = "subproject";};
    }
    {
      name = "root";
      systems = ["x86_64-linux"];
      subprojects.subproject = {
        name = "subproject";
        systems = ["x86_64-linux"];
      };
    };

  "test subproject systems can be overridden" =
    expectRenderedConfig {
      name = "root";
      relativePaths.toRoot = ".";
      systems = ["x86_64-linux"];
      subprojects.subproject = {
        name = "subproject";
        systems = ["aarch64-linux"];
      };
    }
    {
      name = "root";
      systems = ["x86_64-linux"];
      subprojects.subproject = {
        name = "subproject";
        systems = ["aarch64-linux"];
      };
    };
}
