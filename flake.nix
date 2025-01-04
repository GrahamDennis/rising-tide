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
          systems = import systems;
          perSystem =
            { system, pkgs, ... }:
            {
              packages.project-docs =
                (pkgs.nixosOptionsDoc {
                  inherit
                    (lib.evalModules {
                      modules = [
                        self.modules.flake.project
                        {
                          options.defaultSettings = flake-parts.lib.mkPerSystemOption {
                            config = {
                              _module.args.toolsPkgs = pkgs;
                            };
                          };
                        }
                      ];
                    })
                    options
                    ;
                  documentType = "none";
                  warningsAreErrors = false;
                }).optionsCommonMark;
            };
          flake = {
            inherit modules self;
          };
        }
      );
}
