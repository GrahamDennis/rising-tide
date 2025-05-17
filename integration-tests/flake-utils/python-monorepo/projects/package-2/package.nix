# python packages context
{ python }:
python.pkgs.buildPythonPackage rec {
  name = "package-2";
  pyproject = true;
  src = ./.;

  dependencies = with python.pkgs; [
    package-1
    requests
    types-requests
  ];

  # FIXME: These should end up in the dev shell automatically
  optional-dependencies = {
    dev = with python.pkgs; [
      pytest
      pytest-cov
    ];
  };

  nativeCheckInputs = optional-dependencies.dev;

  build-system = with python.pkgs; [ hatchling ];
}
