{
  description = "cpp-package";

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
        project = rising-tide.lib.mkProject system {
          name = "cpp-package";
          settings.tools.go-task = {
            enable = true;
          };
        };
        injector = rising-tide.lib.mkInjector "injector" { args = { inherit project system; }; };
      in
      rec {
        packages.default = pkgs.callPackage (injector.inject ./package.nix) { };
        devShells.default = pkgs.mkShell {
          inputsFrom = [ packages.default ];
          nativeBuildInputs = project.tools;
        };
      }
    );
}
