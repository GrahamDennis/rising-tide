{
  description = "protobuf example";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs =
    inputs@{
      flake-utils,
      nixpkgs,
      self,
      ...
    }:
    let
      # Consumers of rising-tide should add rising-tide as a flake input above. This unusual structure only exists
      # inside of rising-tide to enable the integration tests to run against the local rising-tide repo.
      rising-tide = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
      perSystemOutputs = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };

          project = rising-tide.lib.mkProject {
            inherit pkgs;
            root = ./.;
          } (import ./project.nix);
        in
        {
          inherit project;
          inherit (project)
            devShells
            packages
            hydraJobs
            legacyPackages
            ;
        }
      );
      systemIndependentOutputs = rising-tide.lib.project.mkSystemIndependentOutputs {
        rootProjectBySystem = perSystemOutputs.project;
      };
    in
    perSystemOutputs
    // {
      inherit inputs;
      inherit (systemIndependentOutputs) overlays pythonOverlays;
    };
}
