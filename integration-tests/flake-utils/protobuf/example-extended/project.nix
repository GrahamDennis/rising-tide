# project context
{
  pkgs,
  ...
}:
{
  languages.protobuf = {
    enable = true;
    grpc.enable = true;
    importPaths = {
      example = pkgs.example-src;
    };
    cpp.extraDependencies = pkgs: [
      {
        package = pkgs.example-cpp;
        packageName = "example-cpp";
        protobufLibraryNames = [ "example-cpp::proto" ];
        grpcLibraryNames = [ "example-cpp::grpc" ];
      }
    ];
    python.extraDependencies = pythonPackages: [ pythonPackages.example-py ];
  };
  # Demonstrate naming the generated package as something different from the subproject name.
  # For example this is useful for matching existing legacy naming schemes
  subprojects.example-extended-py.packageName = "example-extended-py-with-custom-name";
}
