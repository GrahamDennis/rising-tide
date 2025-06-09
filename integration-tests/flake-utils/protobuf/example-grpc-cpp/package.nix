# pkgs context
{
  clangStdenv,
  pkgs,
  lib,
}:
clangStdenv.mkDerivation {
  name = "example-grpc-cpp";

  # Minimise rebuilds due to changes to files that don't impact the build
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./CMakeLists.txt
      ./src
      # ./tests
    ];
  };

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
  ];
  buildInputs = with pkgs; [ example-cpp abseil-cpp grpc protobuf ];

  doCheck = true;
  checkInputs = with pkgs; [ gtest ];
}
