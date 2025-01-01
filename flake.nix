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
    risingTideLib = import (root + "/lib") {inherit lib;};
    bootstrapInjector = risingTideLib.mkInjector {
      args = {inherit root lib risingTideLib inputs;};
      name = "bootstrapInjector";
    };
  in
    flake-parts.lib.mkFlake {
      inherit inputs;
    } ({
      self,
      injector,
      ...
    }: let
      flakeModules.injector = bootstrapInjector.inject ./modules/flake/injector.nix;
      flakeModules.risingTideLib = bootstrapInjector.inject ./modules/flake/risingTideLib.nix;
    in {
      imports = [flakeModules.injector flakeModules.risingTideLib];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        pkgs,
        injector',
        ...
      }: let
      in {
        # FIXME: temporary
        packages.default = pkgs.emptyFile;

        devShells.default = injector'.inject ./devShell.nix;
      };
      flake = {
        inherit flakeModules self;
        lib = risingTideLib;
        tests.lib = injector.inject ./lib/tests.nix;
      };
    });
}
