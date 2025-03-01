# python packages context
{
  clangStdenv,
  pkgs,
}:
clangStdenv.mkDerivation {
  name = "cpp-package";
  src = ./.;

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
  ];
  buildInputs = with pkgs; [ fmt ];

  doCheck = true;
  checkInputs = with pkgs; [ gtest ];
}
