# rising-tide flake context
{ injector, ... }:
builtins.mapAttrs (_name: injector.inject) {
  # keep-sorted start
  attrs = ./attrs.nix;
  injector = ./injector.nix;
  overlays = ./overlays.nix;
  project = ./project.nix;
  types = ./types.nix;
  # keep-sorted end
}
