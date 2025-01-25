{
  project ? null,
}:
# python packages context
{ pythonPackages, lib }:
pythonPackages.buildPythonPackage rec {
  name = "package-3";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [ package-1 ];

  nativeCheckInputs = lib.optionals (project != null) project.allTools;

  build-system = with pythonPackages; [ hatchling ];
}
