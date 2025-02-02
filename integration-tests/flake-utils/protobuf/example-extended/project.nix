# project context
{
  ...
}:
{
  languages.protobuf = {
    enable = true;
    grpc.enable = true;
    importPaths = {
      example = ../example/proto;
    };
    python.extraDependencies = pythonPackages: [ pythonPackages.example-py ];
  };
}
