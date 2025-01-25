{
  description = "protobuf example";

  inputs = {
    rising-tide.url = "path:../../../";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs =
    {
      rising-tide,
      flake-utils,
      nixpkgs,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        project = rising-tide.lib.mkProject system {
          name = "protobuf-root";
          subprojects = {
            proto-apis = import ./proto-apis/project.nix;
          };
        };
      in
      rec {
        inherit project;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = project.allTools ++ project.subprojects.proto-apis.allTools;
        };
      }
    );
}
