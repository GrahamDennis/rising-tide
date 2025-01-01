# rising-tide flake context
{inputs, ...}:
# rising-tide perSystem context 
{pkgs, ...}: 
pkgs.mkShell {
    name = "rising-tide-root";
    nativeBuildInputs = with pkgs; [ nix-unit go-task ];
}