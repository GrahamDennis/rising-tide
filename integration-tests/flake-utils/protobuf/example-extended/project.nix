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
  # Demonstrate naming the generated package as something different from the subproject name.
  # For example this is useful for matching existing legacy naming schemes
  subprojects.example-extended-py.packageName = "example-extended-py-with-custom-name";
}
