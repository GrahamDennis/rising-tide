{
  description = "python-monorepo";

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
        name = "python-monorepo-root";
        systems = flake-utils.lib.defaultSystems;
        subprojects = {
          package-1 = import ./projects/package-1/project.nix;
          package-2 = {
            relativePaths.toParentProject = "projects/package-2";
            settings.python.enable = true;
          };
        };
      };
      pythonOverlay =
        python-final: _python-prev:
        let
          system = python-final.pkgs.system;
        in
        {
          package-1 =
            python-final.callPackage
              (project.subprojects.package-1.settings.${system}.python.callPackageFunction)
              { };
          package-2 = python-final.callPackage (import ./projects/package-2 {
            inherit system;
            project = project.subprojects.package-2;
          }) { };
        };
      nixpkgsOverlay = _final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [ pythonOverlay ];
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (
          import nixpkgs {
            overlays = [ nixpkgsOverlay ];
            inherit system;
          }
        );
        pythonPackages = pkgs.python3.pkgs;
      in
      rec {
        packages = { inherit (pythonPackages) package-1 package-2; };

        devShells.default = pkgs.mkShell {
          inputsFrom = [
            packages.package-1
            packages.package-2
          ];
          nativeBuildInputs = project.tools.${system};
        };
      }
    );
}
