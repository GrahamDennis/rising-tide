{
  name = "python-monorepo-root";
  subprojects = {
    package-1 = import ./projects/package-1/project.nix;
    package-2 = import ./projects/package-2/project.nix;
    package-3 = import ./projects/package-3-with-no-tests/project.nix;
  };
}
