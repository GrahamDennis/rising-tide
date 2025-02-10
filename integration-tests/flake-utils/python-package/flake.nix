{
  description = "python-package";

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
          project = rising-tide.lib.mkProject { inherit pkgs; } {
            name = "python-package";
            languages.python.enable = true;
            languages.python.callPackageFunction = import ./package.nix;
          };
        in
        {
          inherit project;
          inherit (project) packages devShells;
        }
      );
      systemIndependentOutputs = rising-tide.lib.project.mkSystemIndependentOutputs {
        rootProjectBySystem = perSystemOutputs.project;
      };
    in
    perSystemOutputs // systemIndependentOutputs // { inherit inputs; };
}
