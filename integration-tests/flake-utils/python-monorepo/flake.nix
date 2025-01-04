{
  description = "python-monorepo";

  inputs = {
    rising-tide.url = "../../..";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "rising-tide/nixpkgs";
  };

  outputs =
    inputs@{
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
          # package-1 and package-2 demonstrate two different ways to integrate.
          # package-1 defines the project configuration and the callPackage function in a project.nix file.
          package-1 = import ./projects/package-1/project.nix;
          # package-2 defines the project configuration in this flake.nix file and defines the callPackage function
          # in a default.nix file mostly as per normal, but with a wrapping lambda function to pass through the subproject
          # (and its tools) into the callPackage function.
          package-2 = {
            relativePaths.toParentProject = "projects/package-2";
            settings.python = {
              enable = true;
              callPackageFunction = (import ./projects/package-2 { project = project.subprojects.package-2; });
            };
          };
        };
      };
      pythonOverlay = project.pythonOverlay;
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
    )
    // {
      inherit project inputs pythonOverlay;
    };
}
