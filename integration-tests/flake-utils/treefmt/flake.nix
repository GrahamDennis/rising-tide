{
  description = "treefmt integration test";

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
          name = "treefmt-integration-test";
          relativePaths.toRoot = "./.";
          tools.treefmt = {
            enable = true;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "treefmt-integration-test";
          nativeBuildInputs = project.allTools;
        };
      }
    );
}
