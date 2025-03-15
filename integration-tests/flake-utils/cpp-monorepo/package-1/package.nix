# python packages context
{
  clangStdenv,
  pkgs,
}:
clangStdenv.mkDerivation {
  name = "package-1";
  src = ./.;

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
  ];
  buildInputs = with pkgs; [ fmt ];

  doCheck = true;
  checkInputs = with pkgs; [ gtest ];
}
