# python packages context
{ python }:
python.pkgs.buildPythonPackage {
  name = "python-package-1";
  pyproject = true;
  src = ./.;

  dependencies = with python.pkgs; [
    example-py
    example-extended-py-with-custom-name
    protobuf
    types-protobuf
    grpcio
  ];

  pythonImportsCheck = [ "python_package_1" ];

  build-system = with python.pkgs; [ hatchling ];
}
