{
  buildPythonPackage,
  fetchPypi,
  protobuf,
  grpcio,
  setuptools,
}:

# This package should be updated together with the main grpc package and other
# related python grpc packages.
# nixpkgs-update: no auto update
buildPythonPackage rec {
  pname = "grpc-stubs";
  version = "1.53.0.5";
  pyproject = true;

  src = fetchPypi {
    pname = "grpc-stubs";
    inherit version;
    hash = "sha256-PhtkJ3XLw+DGMyz87fzLAiF224flGHV77zoSQTl75AY=";
  };

  outputs = [
    "out"
    "dev"
  ];

  enableParallelBuilding = true;

  build-system = [ setuptools ];

  pythonRelaxDeps = [
    "protobuf"
    "grpcio"
  ];

  dependencies = [
    protobuf
    grpcio
    setuptools
  ];

  # no tests in the package
  doCheck = false;
}
