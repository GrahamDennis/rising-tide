# rising-tide flake context
{
  injector,
  ...
}:
# project context
{
  imports = injector.injectModules [
    # keep-sorted start
    ./alejandra.nix
    ./buf.nix
    ./circleci.nix
    ./clang-format
    ./clang-tidy.nix
    ./clangd.nix
    ./cmake-format.nix
    ./cmake.nix
    ./cue.nix
    ./deadnix.nix
    ./direnv
    ./go-task
    ./jetbrains.nix
    ./keep-sorted.nix
    ./lefthook.nix
    ./mdformat.nix
    ./mypy.nix
    ./nil.nix
    ./nix-unit.nix
    ./nixago
    ./nixfmt-rfc-style.nix
    ./protolint.nix
    ./pytest.nix
    ./ripsecrets.nix
    ./ruff.nix
    ./shellcheck.nix
    ./shfmt.nix
    ./statix.nix
    ./taplo.nix
    ./treefmt.nix
    ./uv
    ./vscode.nix
    # keep-sorted end
  ];
}
