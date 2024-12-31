{
  description = "Standardardised nix utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs @ { self, nixpkgs, flake-parts, ... }: let
    root = ./.;
    lib = nixpkgs.lib;
    risingTideLib = import (root + "/lib") {inherit lib;};
    injector = risingTideLib.mkInjector { args = { inherit root lib risingTideLib inputs;}; };
  in     flake-parts.lib.mkFlake {
      inherit inputs;
      specialArgs = {
        inherit root risingTideLib injector;
      };
  } ({self, ...}: let in {
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
    perSystem = { pkgs, system, ...}: let
      injector' = injector.mkChildInjector { args = { inherit pkgs system; }; injectorArgName = "injector'"; };
    in {
      # FIXME: temporary
      packages.default = pkgs.emptyFile;

      devShells.default = injector'.inject ./devShell.nix;
    };
    flake = {
      inherit self;
      lib = risingTideLib;
      tests.lib = injector.inject ./lib/tests.nix;
    };
  })
;
}
