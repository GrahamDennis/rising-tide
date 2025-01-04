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
          package-1 = {
            relativePaths.toParentProject = "projects/package-1";
            settings.python.enable = true;
          };
          package-2 = {
            relativePaths.toParentProject = "projects/package-2";
            settings.python.enable = true;
          };
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python3.pkgs;
      in
      rec {
        packages.package-1 = pythonPackages.callPackage (import ./projects/package-1 {
          inherit system;
          project = project.subprojects.package-1;
        }) { };
        packages.package-2 = pythonPackages.callPackage (import ./projects/package-2 {
          inherit system;
          project = project.subprojects.package-2;
        }) { };

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
