# python packages context
{ pythonPackages }:
pythonPackages.buildPythonPackage {
  name = "python-package-1";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [
    example-py
    example-extended-py-with-custom-name
    protobuf
    types-protobuf
  ];

  pythonImportsCheck = [ "python_package_1" ];

  build-system = with pythonPackages; [ hatchling ];
}
