{
  description = "python-package";

  inputs = {
    rising-tide.url = "../../..";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "rising-tide/nixpkgs";
  };

  outputs =
    {
      self,
      flake-utils,
      rising-tide,
      nixpkgs,
      ...
    }:
    let
      project = rising-tide.lib.mkProject {
        name = "python-package";
        systems = flake-utils.lib.defaultSystems;
        settings.python.enable = true;
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python3.pkgs;
        injector = rising-tide.lib.mkInjector "injector" { args = { inherit project system; }; };
      in
      {
        packages.default = pythonPackages.callPackage (injector.inject ./package.nix) { };
      }
    );
}
