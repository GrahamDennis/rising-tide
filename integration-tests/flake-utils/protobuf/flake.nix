{
  description = "protobuf example";

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
      rising-tide = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        project =
          rising-tide.lib.project.mkProjectWith
            {
              inherit pkgs;
              root = ./.;
            }
            {
              name = "protobuf-root";
              subprojects = {
                example = import ./example/project.nix;
              };
            };
      in
      {
        inherit project;

        packages.python-generated = pkgs.python3.pkgs.callPackage (./example/python-generated.nix) { };
        packages.fileDescriptorSet =
          project.subprojects.example.languages.protobuf.fileDescriptorSet.package;
        packages.generatedPython = project.subprojects.example.languages.protobuf.python.generated.package;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = project.allTools ++ project.subprojects.example.allTools;
        };
      }
    );
}
