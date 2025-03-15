# project context
{
  ...
}:
{
  relativePaths.fromParentProject = "package-2";
  name = "package-2";
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
