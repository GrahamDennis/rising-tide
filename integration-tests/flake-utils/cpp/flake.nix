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
    let
      project = rising-tide.lib.mkProject {
        name = "cpp-package";
        systems = flake-utils.lib.defaultSystems;
        settings.tools.go-task = {
          enable = true;
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        injector = rising-tide.lib.mkInjector "injector" { args = { inherit project system; }; };
      in
      rec {
        packages.default = pkgs.callPackage (injector.inject ./package.nix) { };
        devShells.default = pkgs.mkShell {
          inputsFrom = [ packages.default ];
          nativeBuildInputs = project.tools.${system};
        };
      }
    );
}
