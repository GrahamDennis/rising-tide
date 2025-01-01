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
      args = {inherit root lib inputs self risingTideBootstrapLib; };
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
      flakeModules = {
        risingTideLib = bootstrapInjector.injectModule ./modules/flake/risingTideLib.nix;
        injector = bootstrapInjector.injectModule ./modules/flake/injector.nix;
        project = injector.injectModule ./modules/flake/projects/project.nix;
      };
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
        lib = injector.inject ./lib;
        tests = builtins.mapAttrs (name: injector.inject) {
          lib = ./lib/tests.nix;
          project = ./modules/flake/projects/project.tests.nix;
        };
      };
    });
}
