{
  description = "python-monorepo";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs =
    inputs@{
      flake-utils,
      nixpkgs,
      self,
      ...
    }:
    let
      rising-tide = builtins.getFlake "path:${builtins.toString ../../..}";
      pythonOverlay =
        python-final: python-previous:
        let
          inherit (python-previous.pkgs) system;
        in
        self.project.${system}.languages.python.pythonOverlay python-final python-previous;
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
        project = rising-tide.lib.mkProject system {
          name = "python-monorepo-root";
          subprojects = {
            # package-1 and package-2 demonstrate two different ways to integrate.
            # package-1 defines the project configuration and the callPackage function in a project.nix file.
            package-1 = import ./projects/package-1/project.nix;
            # package-2 defines the project configuration in this flake.nix file and defines the callPackage function
            # in a default.nix file mostly as per normal, but with a wrapping lambda function to pass through the subproject
            # (and its tools) into the callPackage function.
            package-2 = {
              relativePaths.toParentProject = "projects/package-2";
              languages.python = {
                enable = true;
                callPackageFunction = (import ./projects/package-2 { project = project.subprojects.package-2; });
              };
            };
            package-3 = {
              relativePaths.toParentProject = "projects/package-3-with-no-tests";
              languages.python = {
                enable = true;
                testRoots = [ ];
                callPackageFunction = (
                  import ./projects/package-3-with-no-tests { project = project.subprojects.package-3; }
                );
              };
            };
          };
        };
      in
      rec {
        inherit project;
        packages = { inherit (pythonPackages) package-1 package-2 package-3; };

        devShells.default = pkgs.mkShell {
          inputsFrom = [
            packages.package-1
            packages.package-2
            packages.package-3
          ];
          nativeBuildInputs = project.allTools;
        };
      }
    )
    // {
      inherit inputs;
      pythonOverlays.default = pythonOverlay;
      overlays.default = nixpkgsOverlay;
    };
}
