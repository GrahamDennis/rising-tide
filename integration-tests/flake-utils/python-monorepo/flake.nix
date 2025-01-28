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
      rising-tide = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
      perSystemOutputs = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
          pythonPackages = pkgs.python3.pkgs;
          project = rising-tide.lib.mkProject { inherit system; } {
            name = "python-monorepo-root";
            subprojects = {
              package-1 = import ./projects/package-1/project.nix;
              package-2 = import ./projects/package-2/project.nix;
              package-3 = import ./projects/package-3-with-no-tests/project.nix;
            };
          };
        in
        rec {
          inherit project;
          packages = { inherit (pythonPackages) package-1 package-2 package-3; };

          # FIXME: desired output structure:
          # * devShells.default => root
          # * devShells."subproject" => subproject
          # * devShells."subproject/child" => subproject/child
          # or should we use `:` as a separateor to align with taskfile?
          devShells.default = pkgs.mkShell {
            inputsFrom = [
              # FIXME: how should packages be namespaced?
              # It should be possible to separate internal project organisation from
              # external package structure.
              packages.package-1
              packages.package-2
              packages.package-3
            ];
            nativeBuildInputs =
              project.allTools
              # FIXME: This should be automatic
              ++ project.subprojects.package-1.allTools
              ++ project.subprojects.package-2.allTools
              ++ project.subprojects.package-3.allTools;
          };
        }
      );
      systemIndependentOutputs = rising-tide.lib.project.mkSystemIndependentOutputs {
        rootProjectBySystem = perSystemOutputs.project;
      };

    in
    perSystemOutputs
    // {
      inherit (systemIndependentOutputs) overlays pythonOverlays;
      inputs = inputs // {
        inherit rising-tide;
      };
    };
}
