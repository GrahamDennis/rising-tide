# python packages context
{ pythonPackages }:
pythonPackages.buildPythonPackage rec {
  name = "package-2";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [
    package-1
    requests
    types-requests
  ];

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
