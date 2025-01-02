{
  description = "treefmt integration test";

  inputs = {
    rising-tide.url = "../../..";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "rising-tide/nixpkgs";
  };

  outputs = {
    self,
    flake-utils,
    rising-tide,
    nixpkgs,
    ...
  }: let
    project = rising-tide.lib.mkProject {
      name = "treefmt-integration-test";
      relativePaths.toRoot = "./.";
      systems = flake-utils.lib.defaultSystems;
      perSystem.tools.treefmt = {
        enable = true;
      };
    };
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        name = "treefmt-integration-test";
        nativeBuildInputs =
          project.tools.${system}.nativeCheckInputs;
      };
    });
}
