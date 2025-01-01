# rising-tide flake context
{injector, lib, withSystem, ...}:
let inherit (lib) types; in
# project per-system tools context
{system, ...}:
{ 
  imports = builtins.map injector.injectModule [  
    ./go-task
     ./nixago
      ./treefmt.nix
      ];
  options = {
    # FIXME: I'm not sure this is the best name
    nativeCheckInputs = lib.mkOption {
      type = types.listOf types.package;
      default = [];
    };
  };
  config = {
  # the pkgs to be used by tools. By default this will be the rising-tide pkgs
  _module.args.pkgs = lib.mkOptionDefault (withSystem system ({pkgs, ...}: pkgs));
};
}