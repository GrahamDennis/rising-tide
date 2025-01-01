# rising-tide flake context
{inputs, ...}:
# rising-tide perSystem context 
{pkgs, ...}: let batsWithLibraries = pkgs.bats.withLibraries (p: [
              p.bats-support
              p.bats-assert
              p.bats-file
            ]);
            in
pkgs.mkShell {
    name = "rising-tide-root";
    nativeBuildInputs = with pkgs; [ nix-unit go-task batsWithLibraries];
}