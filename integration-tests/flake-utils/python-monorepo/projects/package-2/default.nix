{
  project ? null,
}:
# python packages context
{ pythonPackages, lib }:
let
  system = pythonPackages.pkgs.system;
  # Create a filtered src set to reduce rebuilds. This could be replaced with just `./.`
  src = lib.fileset.toSource {
    fileset = files;
    root = ./.;
  };
  files = lib.fileset.unions [
    ./src
    ./tests
    ./pyproject.toml
  ];
in
pythonPackages.buildPythonPackage rec {
  name = "package-2";
  pyproject = true;
  inherit src;

  dependencies = with pythonPackages; [ package-1 ];

  # FIXME: These should end up in the dev shell automatically
  optional-dependencies = {
    dev = with pythonPackages; [
      pytest
      pytest-cov
    ];
  };

  nativeCheckInputs =
    (lib.optionals (project != null) project.tools.${system}) ++ (optional-dependencies.dev);

  build-system = with pythonPackages; [ hatchling ];
}
