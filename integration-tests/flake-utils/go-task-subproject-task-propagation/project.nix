{
  name = "go-task-subproject-task-propagation-integration-test";
  relativePaths.toRoot = "./.";
  subprojects.subproject = {
    relativePaths.toParentProject = "subproject";
    tools.go-task = {
      enable = true;
      taskfile.tasks.hello.cmds = [ "echo 'Hello, World!'" ];
    };
  };
}
