# rising-tide flake context
{
  injector,
  ...
}:
# project context
{
  imports = builtins.map injector.injectModule [
    ./alejandra.nix
    ./cmake-format.nix
    ./cue.nix
    ./deadnix.nix
    ./direnv
    ./go-task
    ./lefthook.nix
    ./mypy.nix
    ./nixago
    ./nix-unit.nix
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
