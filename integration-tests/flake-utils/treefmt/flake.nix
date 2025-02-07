{
  description = "treefmt integration test";

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
          name = "treefmt-integration-test";
          relativePaths.toRoot = "./.";
          tools.treefmt = {
            enable = true;
          };
        };
      in
      {
        inherit project;
        inherit (project) packages devShells;
      }
    );
}
