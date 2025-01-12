# rising-tide flake context
{
  injector,
  ...
}:
# project context
{
  imports = builtins.map injector.injectModule [
    ./alejandra.nix
    ./clang-format
    ./cmake-format.nix
    ./cmake.nix
    ./cue.nix
    ./deadnix.nix
    ./direnv
    ./go-task
    ./lefthook.nix
    ./mypy.nix
    ./nix-unit.nix
    ./nixago
    ./nixfmt-rfc-style.nix
    ./pytest.nix
    ./ruff.nix
    ./shellcheck.nix
    ./shfmt.nix
    ./treefmt.nix
    ./uv
    ./vscode.nix
  ];
}
