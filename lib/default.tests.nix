# rising-tide flake context
{ injector, ... }:
builtins.mapAttrs (_name: injector.inject) {
  attrs = ./attrs.tests.nix;
  injector = ./injector.tests.nix;
  project = ./project.tests.nix;
  types = ./types.tests.nix;
}
