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
    ./nixago
    ./nixfmt-rfc-style.nix
    ./nix-unit.nix
    ./shellcheck.nix
    ./shfmt.nix
    ./treefmt.nix
    ./vscode.nix
  ];
  options = {
    tools.pkgs = lib.mkOption {
      type = types.pkgs;
      default = withSystem system ({ pkgs, ... }: pkgs);
    };
    tools.all = lib.mkOption {
      type = types.listOf types.package;
      internal = true;
      default = [ ];
    };
  };
  config = {
    # the pkgs to be used by tools. By default this will be the rising-tide pkgs.
    _module.args.toolsPkgs = config.tools.pkgs;
  };
}
