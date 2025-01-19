# rising-tide flake context
{ injector, ... }:
builtins.mapAttrs (_name: injector.inject) {
  attrs = ./attrs.nix;
  injector = ./injector.nix;
  project = ./project.nix;
  types = ./types.nix;
}
