{
  description = "protobuf example";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    rising-tide.url = "github:GrahamDennis/rising-tide";
  };

  outputs =
    inputs@{
      flake-utils,
      nixpkgs,
      rising-tide,
      self,
      ...
    }:
    let
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
              };
        in
        {
          inherit project;
          inherit (project) devShells packages;
        }
      );
      systemIndependentOutputs = rising-tide.lib.project.mkSystemIndependentOutputs {
        rootProjectBySystem = perSystemOutputs.project;
      };
    in
    perSystemOutputs
    // systemIndependentOutputs
    // {
      inherit inputs;
    };
}
