{
  name = "protobuf-root";
  subprojects = {
    example = import ./example/project.nix;
    example-curl = {
      callPackageFunction = import ./example-curl/package.nix;
    };
    example-extended = import ./example-extended/project.nix;
    example-extended-curl = {
      callPackageFunction = import ./example-extended-curl/package.nix;
    };
    example-grandchild = import ./example-grandchild/project.nix;
    python-package-1 = import ./python-package-1/project.nix;
  };
  tools.uv.enable = true;
}
