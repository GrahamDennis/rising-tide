# rising-tide flake context
{ lib, self, ... }:
let
  mkConfig =
    configFormat: system: module:
    (lib.evalModules {
      specialArgs = { inherit system; };
      modules = [
        module
        configFormat
      ];
    }).config.configFile;
in
lib.mapAttrs (_name: configFormat: mkConfig configFormat) self.modules.configFormats
