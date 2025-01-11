{
  description = "go-task-subproject-task-propagation-integration-test";

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
          name = "go-task-subproject-task-propagation-integration-test";
          relativePaths.toRoot = "./.";
          subprojects.subproject = {
            relativePaths.toParentProject = "subproject";
            settings.tools.go-task = {
              taskfile.tasks.hello.cmds = [ "echo 'Hello, World!'" ];
            };
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "go-task-subproject-task-propagation-integration-test";
          # Including the subproject manually like this shouldn't normally be necessary because
          # one would typically use `inputsFrom` the subproject package and the subproject package should
          # include its tools in nativeCheckInputs.
          nativeBuildInputs = project.allTools ++ project.subprojects.subproject.allTools;
        };
      }
    );
}
