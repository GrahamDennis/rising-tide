{
  description = "cpp-monorepo";

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
          project = rising-tide.lib.mkProject {
            basePkgs = nixpkgs.legacyPackages.${system};
          } (import ./project.nix);
        in
        rec {
          inherit project;
          inherit (project)
            packages
            devShells
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
      /*
        When using rising-tide externally you should just write something like `perSystemOutputs // systemIndependentOutputs`,
        however due to the way we import rising-tide locally in integration-tests, to avoid infinite recursion,
        it must be clear to the nix evaluator that systemIndependentOutputs doesn't set the `sourceInfo` or `narHash`
        keys.
      */
      inherit (systemIndependentOutputs) overlays pythonOverlays;
      inputs = inputs // {
        inherit rising-tide;
      };
    };
}
