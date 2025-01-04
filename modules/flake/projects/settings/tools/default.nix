# rising-tide flake context
{
  injector,
  lib,
  withSystem,
  ...
}:
let
  inherit (lib) types;
in
# project per-system tools context
{
  system,
  config,
  ...
}:
{
  imports = builtins.map injector.injectModule [
    ./alejandra.nix
    ./go-task
    ./lefthook.nix
    ./mypy.nix
    ./nixago
    ./nixfmt-rfc-style.nix
    ./nix-unit.nix
    ./pytest.nix
    ./ruff.nix
    ./shellcheck.nix
    ./shfmt.nix
    ./treefmt.nix
    ./uv
    ./vscode.nix
  ];
  options = {
    tools.pkgs = lib.mkOption {
      type = types.pkgs;
      default = withSystem system ({ pkgs, ... }: pkgs);
      defaultText = lib.literalMD "`pkgs` defined by rising-tide";
    };
    tools.all = lib.mkOption {
      type = types.listOf types.package;
      internal = true;
      default = [ ];
    };
  };
  config = {
    # the pkgs to be used by tools. By default this will be the rising-tide pkgs.
    _module.args.toolsPkgs = lib.mkOptionDefault config.tools.pkgs;
  };
}
