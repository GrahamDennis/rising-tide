{ python }:
python.pkgs.buildPythonPackage rec {
  name = "package-1";
  pyproject = true;
  src = ./.;

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
