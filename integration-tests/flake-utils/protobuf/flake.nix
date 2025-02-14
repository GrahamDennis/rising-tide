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

          project =
            rising-tide.lib.mkProject
              {
                inherit pkgs;
                root = ./.;
              }
              {
                name = "protobuf-root";
                # namespacePath = [
                #   "rising-tide"
                #   "integration-tests"
                #   "protobuf"
                # ];
                subprojects = {
                  example = import ./example/project.nix;
                  example-curl = {
                    callPackageFunction = import ./example-curl/package.nix;
                  };
                  example-extended = import ./example-extended/project.nix;
                  example-extended-curl = {
                    callPackageFunction = import ./example-extended-curl/package.nix;
                  };
                  python-package-1 = import ./python-package-1/project.nix;
                };
                tools.uv.enable = true;
                mkShell.nativeBuildInputs = with pkgs; [
                  nix-eval-jobs
                  nix-fast-build
                  nix-output-monitor
                ];
              };
        in
        {
          inherit project;
          inherit (project) devShells packages hydraJobs;
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
