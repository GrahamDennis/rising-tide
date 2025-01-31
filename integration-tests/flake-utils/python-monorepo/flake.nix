{
  description = "python-monorepo";

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
      rising-tide = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
      perSystemOutputs = flake-utils.lib.eachDefaultSystem (
        system:
        let
          # FIXME: Make this really easy to do somehow. Perhaps by letting folks pass a nixpkgs without
          # the overlay applied to the project
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
          project = rising-tide.lib.mkProject { inherit pkgs; } {
            name = "python-monorepo-root";
            subprojects = {
              package-1 = import ./projects/package-1/project.nix;
              package-2 = import ./projects/package-2/project.nix;
              package-3 = import ./projects/package-3-with-no-tests/project.nix;
            };
          };
        in
        rec {
          inherit project;
          inherit (project) packages devShells;
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
