# project context
{
  ...
}:
{
  relativePaths.toParentProject = "example-extended";
  languages.protobuf = {
    enable = true;
    grpc.enable = true;
    importPaths = [ ../example/proto ];
  };
}
