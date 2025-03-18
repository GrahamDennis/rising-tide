{ pythonPackages }:
pythonPackages.buildPythonPackage rec {
  name = "consumer-py";
  pyproject = true;
  src = ./.;

  dependencies = with pythonPackages; [
    pymavlink
  ];

  optional-dependencies = {
    dev = with pythonPackages; [
      pytest
    ];
  };

  nativeCheckInputs = optional-dependencies.dev;

  build-system = with pythonPackages; [ hatchling ];
}
