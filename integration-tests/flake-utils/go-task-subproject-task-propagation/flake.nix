{
  description = "go-task-subproject-task-propagation-integration-test";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs =
    {
      flake-utils,
      self,
      ...
    }:
    let
      rising-tide = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        project = rising-tide.lib.mkProject { inherit system; } {
          name = "go-task-subproject-task-propagation-integration-test";
          relativePaths.toRoot = "./.";
          subprojects.subproject = {
            relativePaths.toParentProject = "subproject";
            tools.go-task = {
              enable = true;
              taskfile.tasks.hello.cmds = [ "echo 'Hello, World!'" ];
            };
          };
        };
      in
      {
        inherit project;
        inherit (project) devShells packages;
      }
    );
}
