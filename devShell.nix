# rising-tide flake context
{inputs, ...}:
# rising-tide perSystem context 
{pkgs, ...}: let
  overlay = final: prev: {
    nixVersions = import "${inputs.nixpkgs}/lib/tests/nix-for-tests.nix" { pkgs = prev; };
  };
  pkgsWithOverlay = pkgs.extend overlay;
in
pkgs.mkShell {
    name = "rising-tide-root";
    nativeBuildInputs = with pkgsWithOverlay; [ nix-unit go-task ];
}