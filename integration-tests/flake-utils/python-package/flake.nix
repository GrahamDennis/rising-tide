{
  description = "python-package";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      ...
    }:
    let
      rising-tide = builtins.getFlake "path:${builtins.toString ../../..}?rev=0000000000000000000000000000000000000000";
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python3.pkgs;
        project = rising-tide.lib.mkProject system {
          name = "python-package";
          languages.python.enable = true;
        };
        injector = rising-tide.lib.mkInjector "injector" { args = { inherit project system; }; };
      in
      {
        packages.default = pythonPackages.callPackage (injector.inject ./package.nix) { };
      }
    );
}
