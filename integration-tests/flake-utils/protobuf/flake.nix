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
        python = pkgs.python3.override { packageOverrides = project.languages.python.pythonOverlay; };

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

        packages.fileDescriptorSet =
          project.subprojects.example.languages.protobuf.fileDescriptorSet.package;
        packages.cppGeneratedSources =
          project.subprojects.example.languages.protobuf.cpp.generatedSources.package;
        packages.pythonGeneratedSources =
          project.subprojects.example.languages.protobuf.python.generatedSources.package;
        packages.python =
          python.pkgs.callPackage project.subprojects.example.languages.python.callPackageFunction
            { };
        packages.example-extended-python =
          python.pkgs.callPackage project.subprojects.example-extended.languages.python.callPackageFunction
            { };

        # FIXME: This is awful, improve this.
        devShells.default = pkgs.mkShell {
          inputsFrom = [ packages.example-extended-python ];
          nativeBuildInputs =
            project.allTools
            ++ project.subprojects.example.allTools
            ++ project.subprojects.example-extended.allTools
            ++ project.subprojects.python-package-1.allTools
            ++ [ packages.python ];
        };
      }
    );
}
