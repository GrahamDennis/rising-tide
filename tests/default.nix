# rising-tide flake context
{ injector, lib, ... }:
lib.mapAttrsRecursive (_name: injector.inject) {
  lib = ./lib;
  modules.flake.project = ./projects;
}
