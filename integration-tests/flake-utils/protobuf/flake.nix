{
  description = "protobuf example";

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
    )
    // {
      inherit inputs;
    };
}
