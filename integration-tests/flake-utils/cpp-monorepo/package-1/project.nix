# project context
{
  ...
}:
{
  relativePaths.fromParentProject = "package-1";
  name = "package-1";
  namespacePath = [
    "rising-tide"
    "integration-tests"
    "cpp-monorepo"
  ];
  languages.cpp = {
    enable = true;
    callPackageFunction = import ./package.nix;
  };
}
