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
      self,
      ...
    }:
    let
      rising-tide = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python3.pkgs;
        project = rising-tide.lib.mkProject { inherit system; } {
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
