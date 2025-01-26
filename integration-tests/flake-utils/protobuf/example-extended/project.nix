# project context
{
  lib,
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
  # Breaking should be automatically disabled if the subproject doesn't exist in a prior version...
  tools.buf = {
    breaking.enable = lib.mkForce false;
  };
}
