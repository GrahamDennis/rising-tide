{
  description = "python-package";

  inputs = {
    rising-tide.url = "../../..";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "rising-tide/nixpkgs";
  };

  outputs =
    {
      flake-utils,
      rising-tide,
      nixpkgs,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python3.pkgs;
        project = rising-tide.lib.mkProject system {
          name = "python-package";
          settings.python.enable = true;
        };
        injector = rising-tide.lib.mkInjector "injector" { args = { inherit project system; }; };
      in
      {
        packages.default = pythonPackages.callPackage (injector.inject ./package.nix) { };
      }
    );
}
