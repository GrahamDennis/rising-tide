{
  description = "Standardardised nix utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }: let
    root = ./.;
    lib = nixpkgs.lib;
    risingTideBootstrapLib = import (root + "/lib/bootstrap.nix") {inherit lib;};
    bootstrapInjector = risingTideBootstrapLib.mkInjector {
      args = {inherit root lib inputs self risingTideBootstrapLib;};
      name = "bootstrapInjector";
    };
  in
    flake-parts.lib.mkFlake {
      inherit inputs;
    } ({self, ...}: let
      modules.flake = {
        risingTideLib = bootstrapInjector.injectModule ./modules/flake/risingTideLib.nix;
        injector = bootstrapInjector.injectModule ./modules/flake/injector.nix;
      };
    in {
      imports = [inputs.flake-parts.flakeModules.modules modules.flake.injector modules.flake.risingTideLib ./flake-modules.nix];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      flake = {
        inherit modules self;
      };
    });
}
