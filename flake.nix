{
  description = "Standardardised nix utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nixago.url = "github:nix-community/nixago";
    nixago.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    let
      root = ./.;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      lib = nixpkgs.lib;
      risingTideBootstrapLib = import (root + "/lib/bootstrap.nix") { inherit lib; };
      bootstrapInjector = risingTideBootstrapLib.mkInjector "bootstrapInjector" {
        args = {
          inherit
            root
            lib
            inputs
            self
            risingTideBootstrapLib
            ;
        };
      };
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      (
        { self, ... }:
        let
          modules.flake = {
            risingTideLib = bootstrapInjector.injectModule ./modules/flake/risingTideLib.nix;
            injector = bootstrapInjector.injectModule ./modules/flake/injector.nix;
          };
        in
        {
          imports = [
            inputs.flake-parts.flakeModules.modules
            modules.flake.injector
            modules.flake.risingTideLib
            ./flake-modules.nix
          ];
          debug = true;
          inherit systems;
          flake = {
            inherit modules self;
          };
        }
      );
}
