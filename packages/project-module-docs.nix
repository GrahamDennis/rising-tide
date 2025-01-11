# rising-tide flake context
{
  lib,
  self,
  ...
}:
# pkgs context
{ pkgs }:
let
  inherit (pkgs) system;
  fixupsModule = {
    options = {
      _module.args = lib.mkOption {
        internal = true;
      };
    };
    config = {
      toolsPkgs = pkgs;
      relativePaths.toRoot = "./.";
    };
  };

  evaluatedProjectModule = lib.evalModules {
    specialArgs = {
      inherit system;
      projectModules = [ ];
    };
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
