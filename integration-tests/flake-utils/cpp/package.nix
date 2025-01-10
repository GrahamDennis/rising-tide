# project injector context
{
  project,
  system,
  ...
}:
# python packages context
{ stdenv, pkgs }:
stdenv.mkDerivation {
  name = project.name;
  src = ./.;

  # FIXME: this is not the right place for lldb
  buildInputs = with pkgs; [
    cmake
    ninja
    fmt
    gtest
    lldb
  ];

  nativeCheckInputs = project.tools.${system} ++ [ pkgs.lldb ];
}
