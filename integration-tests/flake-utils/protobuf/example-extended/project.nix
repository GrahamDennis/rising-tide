# project context
{
  ...
}:
{
  relativePaths.toParentProject = "example-extended";
  languages.protobuf = {
    enable = true;
    grpc.enable = true;
    importPaths = {
      example = ../example/proto;
    };
    python.extraDependencies = pythonPackages: [ pythonPackages.example ];
  };
}
