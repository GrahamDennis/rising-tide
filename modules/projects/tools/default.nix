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
    ./coverage-py.nix
    ./cue.nix
    ./deadnix.nix
    ./direnv
    ./gitignore.nix
    ./go-task
    ./jetbrains
    ./keep-sorted.nix
    ./lefthook.nix
    ./managedFiles
    ./mdformat.nix
    ./mypy.nix
    ./nil.nix
    ./nix-fast-build.nix
    ./nix-unit.nix
    ./nixago.nix
    ./nixfmt-rfc-style.nix
    ./protolint.nix
    ./pyright.nix
    ./pytest.nix
    ./ripsecrets.nix
    ./ruff.nix
    ./shellHooks
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
