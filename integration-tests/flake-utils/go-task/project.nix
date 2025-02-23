{
  name = "go-task-integration-test";
  tools.go-task = {
    enable = true;
    taskfile.tasks.hello.cmds = [ "echo 'Hello, World!'" ];
  };
}
