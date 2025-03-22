{ pythonPackages }:
pythonPackages.buildPythonPackage {
  name = "consumer-py";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [
    pymavlink
    example-py
  ];

  pythonImportsCheck = [ "consumer_py" ];

  build-system = with pythonPackages; [ hatchling ];
}
