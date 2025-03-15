{
  name = "go-task-subproject-task-propagation-integration-test";
  subprojects.subproject = {
    relativePaths.fromParentProject = "subproject";
    mkShell.enable = true;
    tools.go-task = {
      enable = true;
      taskfile.tasks.hello.cmds = [ "echo 'Hello, World!'" ];
    };
  };
}
