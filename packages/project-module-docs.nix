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
      name = "‹name›";
      _module.args.pkgs = pkgs;
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

  # Logic copied from nixpkgs/doc/doc-support/options-doc.nix
  root = toString self;

  transformDeclaration =
    decl:
    let
      declStr = toString decl;
      subpath = lib.removePrefix "/" (lib.removePrefix root declStr);
    in
    assert lib.hasPrefix root declStr;
    {
      url = "https://github.com/GrahamDennis/rising-tide/blob/main/${subpath}";
      name = subpath;
    };

in
(pkgs.nixosOptionsDoc {
  inherit (evaluatedProjectModule) options;
  documentType = "none";
  transformOptions = opt: opt // { declarations = map transformDeclaration opt.declarations; };
  warningsAreErrors = false;
}).optionsCommonMark
