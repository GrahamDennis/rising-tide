{...}:
{pkgs, ...}:
pkgs.mkShell {
    name = "rising-tide-root";
    nativeBuildInputs = [ pkgs.nix-unit ];
}