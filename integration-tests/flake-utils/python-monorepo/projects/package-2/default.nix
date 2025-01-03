{
  project,
  system,
  ...
}:
# python packages context
{ pythonPackages }:
pythonPackages.buildPythonPackage rec {
  name = project.name;
  pyproject = true;
  src = ./.;

  # FIXME: These should end up in the dev shell automatically
  optional-dependencies = {
    dev = with pythonPackages; [
      pytest
      pytest-cov
    ];
  };

  nativeCheckInputs = project.tools.${system} ++ (optional-dependencies.dev);

  build-system = with pythonPackages; [ hatchling ];
}
