# python packages context
{ python }:
python.pkgs.buildPythonPackage {
  name = "package-3";
  pyproject = true;
  src = ./.;

  dependencies = with python.pkgs; [ package-1 ];

  build-system = with python.pkgs; [ hatchling ];
}
