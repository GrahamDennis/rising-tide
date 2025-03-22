{ pythonPackages }:
pythonPackages.buildPythonPackage {
  name = "mavlink2cue";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [
    pymavlink
  ];

  build-system = with pythonPackages; [ hatchling ];
}
