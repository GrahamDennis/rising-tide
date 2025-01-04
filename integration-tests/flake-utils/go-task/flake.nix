{
  description = "go-task integration test";

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
        name = "go-task-integration-test";
        relativePaths.toRoot = "./.";
        systems = flake-utils.lib.defaultSystems;
        settings.tools.go-task = {
          enable = true;
          taskfile.tasks.hello.cmds = [ "echo 'Hello, World!'" ];
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "go-task-integration-test";
          nativeBuildInputs = project.tools.${system};
        };
      }
    );
}
