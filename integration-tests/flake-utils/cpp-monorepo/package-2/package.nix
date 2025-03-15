# python packages context
{
  clangStdenv,
  pkgs,
}:
clangStdenv.mkDerivation {
  name = "package-2";
  src = ./.;

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
  ];
  buildInputs = with pkgs; [ fmt ];

  doCheck = true;
  checkInputs = with pkgs; [ gtest ];
}
