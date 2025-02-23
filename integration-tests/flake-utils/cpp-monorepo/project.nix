{
  name = "cpp-monorepo";
  subprojects = {
    package-1 = import ./package-1/project.nix;
    package-2 = import ./package-2/project.nix;
  };
}
