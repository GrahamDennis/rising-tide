{
  description = "go-task-subproject-task-propagation-integration-test";

  inputs = {
    rising-tide.url = "../../..";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "rising-tide/nixpkgs";
  };

  outputs =
    {
      self,
      flake-utils,
      rising-tide,
      nixpkgs,
      ...
    }:
    let
      project = rising-tide.lib.mkProject {
        name = "go-task-subproject-task-propagation-integration-test";
        relativePaths.toRoot = "./.";
        systems = flake-utils.lib.defaultSystems;
        subprojects.subproject = {
          relativePaths.toParentProject = "subproject";
          settings.tools.go-task = {
            taskfile.tasks.hello.cmds = [ "echo 'Hello, World!'" ];
          };
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
          name = "go-task-subproject-task-propagation-integration-test";
          # Including the subproject manually like this shouldn't normally be necessary because
          # one would typically use `inputsFrom` the subproject package and the subproject package should
          # include its tools in nativeCheckInputs.
          nativeBuildInputs = project.tools.${system} ++ project.subprojects.subproject.tools.${system};
        };
      }
    );
}
