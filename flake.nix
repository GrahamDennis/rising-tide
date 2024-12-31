{
  description = "Standardardised nix utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = inputs @ { self, nixpkgs, ... }: let
    root = ./.;
    lib = nixpkgs.lib;
    risingTideLib = import (root + "/lib.nix") {inherit lib;};

  in {
    lib = risingTideLib;
  };
}
