# rising-tide flake context
{
  lib,
  inputs,
  ...
}: let
  inherit (lib) types;
in
  # user project context
  {config, ...}: {
    options = {
      systems = lib.mkOption {
        description = ''
          All the system types the project supports;
        '';
        type = types.listOf types.str;
      };
      perSystem = lib.mkOption {
        type = inputs.flake-parts.lib.mkPerSystemType ({system, ...}: {
          _file = ./perSystem.nix;
        });
        default = {};
        apply = modules: system:
          (lib.evalModules {
            inherit modules;
            prefix = ["perSystem" system];
            specialArgs = {
              inherit system;
            };
          })
          .config;
      };

      allSystems = lib.mkOption {
        type = types.lazyAttrsOf types.unspecified;
        internal = true;
      };
    };

    config = {
      allSystems = lib.genAttrs config.systems config.perSystem;
    };
  }
