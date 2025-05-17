# python packages context
{ lib, python }:
python.pkgs.buildPythonPackage {
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

  dependencies = with python.pkgs; [
    requests
    pytest
  ];
  build-system = with python.pkgs; [ hatchling ];

  nativeCheckInputs = with python.pkgs; [ pytestCheckHook ];
  pytestFlagsArray = [ "tests" ];
}
