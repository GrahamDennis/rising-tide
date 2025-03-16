# project context
{
  ...
}:
{
  relativePaths.fromParentProject = "projects/package-3-with-no-tests";
  languages.python = {
    enable = true;
    testRoots = [ ];
    callPackageFunction = import ./package.nix;
  };
}
