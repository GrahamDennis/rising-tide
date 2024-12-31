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
    risingTideLib = import (root + "/lib.nix") {inherit lib;};
    inherit (risingTideLib.mkInjector { inherit root lib risingTideLib inputs; }) inject injectModule;
  in     flake-parts.lib.mkFlake {
      inherit inputs;
      specialArgs = {
        inherit root risingTideLib inject injectModule;
      };
  } ({self, ...}: let in {
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
    perSystem = { pkgs, ...}: {
      # FIXME: temporary
      packages.default = pkgs.emptyFile;
    };
    flake = {
      inherit self;
      lib = risingTideLib;
    };
  })
;
}
