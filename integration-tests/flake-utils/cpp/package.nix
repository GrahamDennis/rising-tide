# project injector context
{
  project,
  ...
}:
# python packages context
{ stdenv, pkgs }:
stdenv.mkDerivation {
  name = project.name;
  src = ./.;

  buildInputs = with pkgs; [
    cmake
    ninja
    fmt
    gtest
  ];
}
