{
  description = "go-task integration test";

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
      # Consumers of rising-tide should add rising-tide as a flake input above. This unusual structure only exists
      # inside of rising-tide to enable the integration tests to run against the local rising-tide repo.
      rising-tide = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        project = rising-tide.lib.mkProject { inherit system; } (import ./project.nix);
      in
      {
        inherit project;
        inherit (project) packages devShells hydraJobs;
      }
    );
}
