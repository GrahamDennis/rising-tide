# python packages context
{ lib, pythonPackages }:
pythonPackages.buildPythonPackage {
  name = "python-package";
  pyproject = true;

  # Minimise rebuilds due to changes to files that don't impact the build
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./pyproject.toml
      ./src
      ./tests
    ];
  };

  dependencies = with pythonPackages; [
    requests
    pytest
  ];
  build-system = with pythonPackages; [ hatchling ];

  nativeCheckInputs = with pythonPackages; [ pytestCheckHook ];
  pytestFlagsArray = [ "tests" ];
}
