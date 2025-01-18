{
  description = "Standardardised nix utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    systems.url = "github:nix-systems/default";
    nixago.url = "github:nix-community/nixago";
    nixago.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      systems,
      ...
    }:
    let
      root = ./.;
      lib = nixpkgs.lib;
      risingTideLib = import (root + "/lib/default.nix") {
        inherit lib self;
      };
      bootstrapInjector = risingTideLib.mkInjector "bootstrapInjector" {
        args = {
          inherit
            root
            lib
            inputs
            risingTideLib
            ;
          risingTide = self;
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
          systems = import systems;
          flake = {
            inherit modules self;
          };
        }
      );
}
