# rising-tide flake context
{
  lib,
  self,
  flake-parts-lib,
  ...
}:
# pkgs context
{ pkgs }:
let
  fixupsModule = {
    options = {
      _module.args = lib.mkOption {
        internal = true;
      };
      defaultSettings = flake-parts-lib.mkPerSystemOption {
        config = {
          _module.args.toolsPkgs = pkgs;
        };
      };
    };
    config = {
      relativePaths.toRoot = "./.";
    };
  };

  evaluatedProjectModule = lib.evalModules {
    modules = [
      self.modules.flake.project
      fixupsModule
    ];
  };
in
(pkgs.nixosOptionsDoc {
  inherit (evaluatedProjectModule) options;
  documentType = "none";
  warningsAreErrors = false;
}).optionsCommonMark
