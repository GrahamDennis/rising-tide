# rising-tide flake context
{
  injector,
  lib,
  ...
}:
let
  inherit (lib) types;
in
# project settings tools context
{
  imports = builtins.map injector.injectModule [
    ./alejandra.nix
    ./deadnix.nix
    ./go-task
    ./lefthook.nix
    ./mypy.nix
    ./nixago
    ./nixfmt-rfc-style.nix
    ./nix-unit.nix
    # ./pytest.nix
    # ./ruff.nix
    # ./shellcheck.nix
    # ./shfmt.nix
    # ./treefmt.nix
    ./uv
    # ./vscode.nix
  ];
  options = {
    # FIXME: Remove this, and replace with config.tools
    tools.all = lib.mkOption {
      type = types.listOf types.package;
      internal = true;
      default = [ ];
    };
  };
}
