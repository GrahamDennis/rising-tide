{ python }:
python.pkgs.buildPythonPackage {
  name = "consumer-py";
  pyproject = true;
  src = ./.;

  dependencies = with python.pkgs; [
    pymavlink
    example-py
  ];

  pythonImportsCheck = [ "consumer_py" ];

  build-system = with python.pkgs; [ hatchling ];
}
