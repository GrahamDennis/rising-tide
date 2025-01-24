# rising-tide flake context
{
  injector,
  ...
}:
# project context
{
  imports = injector.injectModules [
    ./alejandra.nix
    ./buf.nix
    ./clang-format
    ./clang-tidy.nix
    ./cmake-format.nix
    ./cmake.nix
    ./cue.nix
    ./deadnix.nix
    ./direnv
    ./go-task
    ./lefthook.nix
    ./mypy.nix
    ./nil.nix
    ./nix-unit.nix
    ./nixago
    ./nixfmt-rfc-style.nix
    ./protolint.nix
    ./pytest.nix
    ./ruff.nix
    ./shellcheck.nix
    ./shfmt.nix
    ./treefmt.nix
    ./uv
    ./vscode.nix
  ];
}
