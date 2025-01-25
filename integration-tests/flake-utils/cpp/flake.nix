{
  description = "cpp-package";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      self,
      ...
    }:
    let
      rising-tide = builtins.getFlake "path:../../..?narHash=${self.narHash}";
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        project = rising-tide.lib.mkProject system {
          name = "cpp-package";
          languages.cpp.enable = true;
          tools.go-task.enable = true;
        };
        injector = rising-tide.lib.mkInjector "injector" { args = { inherit project system; }; };
      in
      rec {
        packages.default = pkgs.callPackage (injector.inject ./package.nix) { };
        devShells.default = pkgs.mkShell {
          inputsFrom = [ packages.default ];
          nativeBuildInputs = project.allTools;
        };
      }
    );
}
