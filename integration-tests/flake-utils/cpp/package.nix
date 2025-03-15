# python packages context
{
  clangStdenv,
  pkgs,
  lib,
}:
clangStdenv.mkDerivation {
  name = "cpp-package";

  # Minimise rebuilds due to changes to files that don't impact the build
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./CMakeLists.txt
      ./src
      ./tests
    ];
  };

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
  ];
  buildInputs = with pkgs; [ fmt ];

  doCheck = true;
  checkInputs = with pkgs; [ gtest ];
}
