{
  description = "go-task integration test";

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
          name = "go-task-integration-test";
          tools.go-task = {
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
