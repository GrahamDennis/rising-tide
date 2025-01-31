# python packages context
{ pythonPackages }:
pythonPackages.buildPythonPackage {
  name = "python-package";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [
    requests
    pytest
  ];
  build-system = with pythonPackages; [ hatchling ];

  nativeCheckInputs = with pythonPackages; [ pytestCheckHook ];
  pytestFlagsArray = [ "tests" ];
}
