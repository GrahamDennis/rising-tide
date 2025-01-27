# project context
{
  ...
}:
{
  relativePaths.toParentProject = "python-package-1";
  languages.python = {
    enable = true;
    testRoots = [ ];
    callPackageFunction = import ./package.nix;
  };
}
