# rising-tide flake context
{...}:
# rising-tide perSystem context 
{pkgs, ...}:
pkgs.mkShell {
    name = "rising-tide-root";
    nativeBuildInputs = with pkgs; [ nix-unit go-task ];
}