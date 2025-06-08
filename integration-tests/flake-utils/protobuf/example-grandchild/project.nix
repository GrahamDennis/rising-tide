# project context
{
  pkgs,
  ...
}:
{
  languages.protobuf = {
    enable = true;
    importPaths = {
      example = pkgs.example-src;
      example-extended = pkgs.example-extended-src;
    };
    cpp.extraDependencies = pkgs: [
      {
        package = pkgs.example-extended-cpp;
        packageName = "example-extended-cpp";
        protobufLibraryNames = [ "example-extended-cpp::proto" ];
      }
    ];
    python.extraDependencies = pythonPackages: [ pythonPackages.example-extended-py-with-custom-name ];
  };
}
