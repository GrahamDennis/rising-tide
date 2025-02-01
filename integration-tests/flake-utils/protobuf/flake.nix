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
                subprojects = {
                  example = import ./example/project.nix;
                  example-extended = import ./example-extended/project.nix;
                  python-package-1 = import ./python-package-1/project.nix;
                };
                tools.uv.enable = true;
              };
        in
        rec {
          inherit project;
          inherit (project) devShells;

          packages = project.packages // {
            fileDescriptorSet = project.subprojects.example.languages.protobuf.fileDescriptorSet.package;
            cppGeneratedSources = project.subprojects.example.languages.protobuf.cpp.generatedSources.package;
            pythonGeneratedSources =
              project.subprojects.example.languages.protobuf.python.generatedSources.package;

          };
        }
      );
      systemIndependentOutputs = rising-tide.lib.project.mkSystemIndependentOutputs {
        rootProjectBySystem = perSystemOutputs.project;
      };
    in
    perSystemOutputs
    // {
      inherit (systemIndependentOutputs) overlays pythonOverlays;
    };
}
