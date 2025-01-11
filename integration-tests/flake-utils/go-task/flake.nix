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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        project = rising-tide.lib.mkProject system {
          name = "go-task-integration-test";
          settings.tools.go-task = {
            enable = true;
            taskfile.tasks.hello.cmds = [ "echo 'Hello, World!'" ];
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "go-task-integration-test";
          nativeBuildInputs = project.allTools;
        };
      }
    );
}
