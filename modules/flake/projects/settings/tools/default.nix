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
      description = ''
        The nixpkgs package set to be used by project tooling, e.g. shellcheck, ruff, mypy, etc.
        This package set does not need to be the same as is used for building the project itself, to permit
        newer tooling to be used with projects building against older versions of nixpkgs.
      '';
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
