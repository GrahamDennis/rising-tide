{
  description = "cpp-package";

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
          project = rising-tide.lib.mkProject { inherit pkgs; } {
            name = "cpp-package";
            namespacePath = [
              "rising-tide"
              "integration-tests"
              "cpp"
            ];
            languages.cpp.enable = true;
            callPackageFunction = import ./package.nix;
          };
        in
        {
          inherit project;
          inherit (project) packages devShells;
          legacyPackages = pkgs;
        }
      );
      systemIndependentOutputs = rising-tide.lib.project.mkSystemIndependentOutputs {
        rootProjectBySystem = perSystemOutputs.project;
      };
    in
    perSystemOutputs
    // {
      inherit inputs;
      inherit (systemIndependentOutputs) overlays;
    };
}
