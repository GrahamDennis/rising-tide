{
  description = "treefmt integration test";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      ...
    }:
    let
      rising-tide = builtins.getFlake "path:${builtins.toString ../../..}";
    in
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
