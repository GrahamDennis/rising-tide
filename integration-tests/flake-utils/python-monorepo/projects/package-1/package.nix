{ pythonPackages }:
pythonPackages.buildPythonPackage rec {
  name = "package-1";
  pyproject = true;
  src = ./.;

  # FIXME: These should end up in the dev shell automatically
  optional-dependencies = {
    dev = with pythonPackages; [
      pytest
      pytest-cov
    ];
  };

  nativeCheckInputs = optional-dependencies.dev;

  build-system = with pythonPackages; [ hatchling ];
}
