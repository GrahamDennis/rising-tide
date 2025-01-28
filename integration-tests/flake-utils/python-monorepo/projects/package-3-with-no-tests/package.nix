# python packages context
{ pythonPackages }:
pythonPackages.buildPythonPackage {
  name = "package-3";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [ package-1 ];

  build-system = with pythonPackages; [ hatchling ];
}
