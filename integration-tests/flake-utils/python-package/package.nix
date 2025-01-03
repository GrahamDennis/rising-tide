# project injector context
{
  project,
  system,
  ...
}:
# python packages context
{ pythonPackages }:
pythonPackages.buildPythonPackage {
  name = project.name;
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [ requests ];

  nativeCheckInputs = project.tools.${system};

  build-system = with pythonPackages; [ hatchling ];
}
