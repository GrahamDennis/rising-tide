# project injector context
{
  project,
  ...
}:
# python packages context
{ pythonPackages }:
pythonPackages.buildPythonPackage rec {
  name = project.name;
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [ requests ];

  # FIXME: These should end up in the dev shell automatically
  optional-dependencies = {
    dev = with pythonPackages; [
      pytest
      pytest-cov
    ];
  };

  nativeCheckInputs = project.allTools ++ optional-dependencies.dev;

  build-system = with pythonPackages; [ hatchling ];
}
