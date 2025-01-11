{
  project ? null,
}:
# python packages context
{ pythonPackages, lib }:
pythonPackages.buildPythonPackage rec {
  name = "package-2";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [ package-1 ];

  # FIXME: These should end up in the dev shell automatically
  optional-dependencies = {
    dev = with pythonPackages; [
      pytest
      pytest-cov
    ];
  };

  nativeCheckInputs = (lib.optionals (project != null) project.tools) ++ (optional-dependencies.dev);

  build-system = with pythonPackages; [ hatchling ];
}
