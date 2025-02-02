# python packages context
{ pythonPackages }:
pythonPackages.buildPythonPackage {
  name = "python-package-1";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [
    example-py
    example-extended-py
    protobuf
    types-protobuf
  ];

  build-system = with pythonPackages; [ hatchling ];
}
